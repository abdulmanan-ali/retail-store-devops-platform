# EKS Deployment Runbook — retail-store-devops-platform

Real issues hit while standing up the EKS environment, root causes, and the
permanent fixes now codified in Terraform. Kept as a reference for future
rebuilds and as documented proof of debugging work.

---

## 1. Node group failure — `NodeCreationFailure: Unhealthy nodes`

**Symptom**
`terraform apply` on `module.eks` repeatedly failed creating the managed
node group, with nodes never joining the cluster.

**Root cause**
AWS no longer publishes Amazon Linux 2 (AL2) EKS-optimized AMIs for newer
Kubernetes versions. The node group was relying on the module's default
`ami_type`, which resolved to an incompatible/unavailable AMI for the
cluster's Kubernetes version.

**Fix**
Explicitly pin the AMI type on the node group:

```hcl
eks_managed_node_groups = {
  general = {
    ami_type = "AL2023_x86_64_STANDARD"
    # ...
  }
}
```

**Status:** Fixed and codified in `eks.tf`.

---

## 2. EBS CSI driver addon — no IAM permissions

**Symptom**
Not caught until later stages — pods requesting new EBS volumes would have
hung indefinitely with no clear error on the addon itself (`ACTIVE` status
can be misleading; it just means the addon installed, not that it can
authenticate to AWS).

**Root cause**
The `aws-ebs-csi-driver` addon was declared without a
`service_account_role_arn`. Without IRSA (IAM Roles for Service Accounts)
wired in, the driver has no AWS API permissions to create/attach volumes.

**Fix**
Created a dedicated IAM role trusting the cluster's OIDC provider, scoped to
the `ebs-csi-controller-sa` service account, with the
`AmazonEBSCSIDriverPolicy` attached — then passed its ARN into the addon
block:

```hcl
aws-ebs-csi-driver = {
  most_recent               = true
  service_account_role_arn  = aws_iam_role.ebs_csi.arn
}
```

**Status:** Fixed and codified in `eks.tf`.

---

## 3. ArgoCD `argocd-redis-secret-init` — timeout / `CreateContainerConfigError`

**Symptom**
On first ArgoCD install attempt, `argocd-server`, `argocd-repo-server`, and
`argocd-application-controller` all sat in `CreateContainerConfigError`
because the `argocd-redis` secret was never created — the init Job/container
responsible for generating it couldn't reach the Kubernetes API server.

**Root cause**
The `vpc-cni` addon was not guaranteed to be fully active before node compute
came up, meaning pod networking wasn't reliably ready the moment nodes
joined. This caused early pods (including the Redis secret-init container)
to fail reaching the control plane.

**Fix**
Set `before_compute = true` on the `vpc-cni` addon so CNI is provisioned
before any node group is created:

```hcl
addons = {
  vpc-cni = {
    before_compute = true
  }
  # ...
}
```

**Status:** Fixed and codified in `eks.tf`. Confirmed on rebuild — ArgoCD
installed cleanly with all pods `Running` within ~2 minutes, no Redis errors.

---

## 4. `ingress-nginx-admission-create` Job — `BackoffLimitExceeded`

**Symptom**
`helm install ingress-nginx` rolled back with the admission webhook
certificate-generation Job failing repeatedly.

**Root cause**
The admission webhook Jobs (`admission-create` / `admission-patch`) need
reliable pod-to-API-server connectivity at install time — the same class of
networking dependency as issue #3. Rather than chase this further (validating
webhooks are a nice-to-have, not required for ingress to function), the
webhook was disabled outright.

**Fix**

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.admissionWebhooks.enabled=false \
  --set controller.service.type=LoadBalancer
```

**Trade-off:** Loses server-side validation of malformed `Ingress` manifests
before they're applied. Acceptable for a single-operator portfolio project;
would revisit for a team/production setting.

**Status:** Working. Not yet moved into Terraform (still a manual Helm
install) — candidate for future `helm_release` Terraform resource if full
IaC coverage is desired.

---

## 5. Database/queue pods stuck `Pending` — unbound PVCs

**Symptom**
`catalog-db`, `orders-db`, and `rabbitmq` pods stuck in `Pending`.
`kubectl describe pod` showed:

```
0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. not found
```

Downstream effect: `catalog` and `orders` app pods crash-looped with
`connection refused` on their DB hosts — a symptom of issue #5, not a
separate bug.

**Root cause**
No default `StorageClass` existed on the cluster. The EBS CSI driver was
healthy and had correct IAM permissions (issue #2 already fixed), but with no
StorageClass, PVCs had nothing telling them how/where to provision a volume.

**Fix**
Created a default `gp3` StorageClass:

```hcl
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Delete"
  parameters = { type = "gp3" }
}
```

`WaitForFirstConsumer` matters: it delays volume provisioning until a pod is
actually scheduled, avoiding AZ mismatches between the node and the EBS
volume (a common second failure right after fixing the missing-StorageClass
issue).

**Status:** Fixed and codified in `storage.tf`, via the `kubernetes` Terraform
provider (`kubernetes-provider.tf`) rather than a manual `kubectl apply`.

---

## Standard rebuild sequence (post-fix)

```bash
# 1. Terraform: VPC, EKS, node group, addons, IAM, default StorageClass
terraform plan -out=tfplan
terraform apply tfplan

# 2. Point kubectl at the new cluster
aws eks update-kubeconfig --name retail-store-eks --region us-east-1
kubectl get nodes -w   # wait for Ready

# 3. ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm install argocd argo/argo-cd --namespace argocd --version 7.8.15
kubectl get pods -n argocd -w   # confirm no CreateContainerConfigError

# 4. ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.admissionWebhooks.enabled=false \
  --set controller.service.type=LoadBalancer

# 5. Deploy the app via ArgoCD Applications
kubectl apply -f devops/kubernetes/argocd/retail-store-app.yaml
kubectl apply -f devops/kubernetes/argocd/monitoring-app.yaml
kubectl get applications -n argocd
kubectl get pods -n retail-store -w

# 6. Grab the public entry point
kubectl get svc -n ingress-nginx ingress-nginx-controller
curl -I http://<EXTERNAL-IP>
```

## Known remaining gap

ingress-nginx is still installed manually via Helm rather than through
Terraform (`helm_release`) or an ArgoCD-managed Application. Bringing it
under full GitOps/IaC control is the next hardening step.
