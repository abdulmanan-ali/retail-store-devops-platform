# Retail Store DevOps Platform

Production-grade DevOps infrastructure built on top of the [AWS Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app) — a real 5-microservice application (Go, Java, Node.js) used as the foundation to design, build, and operate a full cloud-native delivery pipeline from scratch.

**This repository is not the sample app itself.** It is the DevOps platform — Docker, Terraform, Kubernetes, Helm, CI/CD, GitOps, and Observability — engineered around it.

Built by [Abdul Manan Ali](https://github.com/abdulmanan-ali) — Lahore, Pakistan.

---

## What this project demonstrates

| Area | What was built |
|---|---|
| **Containerization** | Custom multi-stage Dockerfiles for all 5 services (Go, Java/Spring Boot, Node.js/NestJS) — smaller, more secure images than the original |
| **Infrastructure as Code** | AWS VPC + ECR provisioned with official Terraform modules, remote state in S3, state locking via DynamoDB |
| **Container Orchestration** | Full stack running on Kubernetes (Kind locally, AWS EKS for production validation), 10 pods across 5 services + 5 datastores |
| **Package Management** | Custom Helm chart templating all 5 services and databases with a single set of templates and a shared `values.yaml` |
| **CI/CD** | GitHub Actions pipeline — parallel matrix builds, Trivy vulnerability scanning, immutable image tags, automated Helm value updates |
| **GitOps** | ArgoCD continuously syncing the cluster to Git — zero manual `kubectl apply` in the deployment flow |
| **Observability** | Prometheus + Grafana stack with custom dashboards covering all 5 services, JVM/Go/Node.js runtime metrics, and infrastructure health |
| **Security** | 7 real CVEs identified and fixed via the CI pipeline (Thymeleaf SSTI, Tomcat auth bypass, Go TLS bypass, vulnerable npm dependency) |

---

## Application architecture

The underlying sample app intentionally uses multiple languages and persistence backends to mirror a real polyglot microservices environment:

| Component | Language | Persistence | Description |
|---|---|---|---|
| [UI](./src/ui/) | Java (Spring Boot) | — | Storefront, aggregates the other services |
| [Catalog](./src/catalog/) | Go | MySQL/MariaDB | Product catalog API |
| [Cart](./src/cart/) | Java (Spring Boot) | DynamoDB | Shopping cart API |
| [Orders](./src/orders/) | Java (Spring Boot) | PostgreSQL + RabbitMQ | Order management API |
| [Checkout](./src/checkout/) | Node.js (NestJS) | Redis | Orchestrates the checkout flow |

---

## Platform architecture

```
                         ┌─────────────────┐
                         │   GitHub Repo    │  ← single source of truth
                         └────────┬─────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
         ┌──────────────────┐         ┌──────────────────┐
         │  GitHub Actions   │         │     ArgoCD        │
         │  - Build (matrix) │         │  - Watches Git     │
         │  - Trivy scan     │         │  - Auto-syncs      │
         │  - Push to ECR    │         │    cluster state   │
         │  - Update Helm    │         │  - selfHeal: true  │
         └─────────┬─────────┘         └─────────┬──────────┘
                   │                              │
                   ▼                              ▼
            ┌─────────────┐              ┌──────────────────┐
            │   AWS ECR    │◄─────────────│   Kubernetes      │
            │ (5 repos,    │   pulls      │   Cluster          │
            │  SHA tags)   │              │  - 5 services       │
            └─────────────┘              │  - 5 databases       │
                                          │  - Prometheus/Grafana│
                                          └──────────────────────┘
```

---

## Tech stack

- **Containers:** Docker (multi-stage builds)
- **IaC:** Terraform (VPC, ECR, official AWS modules)
- **Orchestration:** Kubernetes (Kind for local dev, AWS EKS for production)
- **Packaging:** Helm 3
- **CI:** GitHub Actions + Trivy
- **CD / GitOps:** ArgoCD
- **Observability:** Prometheus, Grafana, kube-state-metrics
- **Cloud:** AWS (ECR, VPC, S3, DynamoDB, EKS)

---

## Repository structure

```
.
├── src/                          # Microservice source code (Go, Java, Node.js)
├── devops/
│   ├── docker/                   # Custom multi-stage Dockerfiles per service
│   ├── terraform/                # VPC, ECR, remote state config
│   ├── kubernetes/
│   │   ├── base/                 # Raw manifests, ServiceMonitors
│   │   ├── helm/retail-store/    # Helm chart (templates + values.yaml)
│   │   └── argocd/               # ArgoCD Application manifest
│   └── scripts/                  # Load testing, automation scripts
├── .github/workflows/            # CI pipeline (ci.yml)
└── docker-compose.yaml           # Local multi-service stack (reference)
```

---

## Running it locally

### Docker Compose (fastest way to see it working)

```bash
DB_PASSWORD='your_password' docker compose -f docker-compose.yaml up
```

Open `http://localhost:8888`.

### Kubernetes (Kind)

```bash
kind create cluster --name retail-store --config kind-config.yaml
helm install retail-store devops/kubernetes/helm/retail-store -n retail-store --create-namespace
kubectl port-forward svc/ui -n retail-store 8080:8080
```

Open `http://localhost:8080`.

### Monitoring

```bash
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Open `http://localhost:3000`.

---

## CI/CD pipeline

On every push to `main`:

1. All 5 services build in parallel (matrix strategy)
2. Trivy scans each image and **blocks the pipeline on CRITICAL vulnerabilities**
3. Images are pushed to ECR with immutable, commit-SHA tags
4. A sequential job updates the Helm chart's `values.yaml` with new tags
5. ArgoCD detects the Git change and syncs the cluster automatically

No image is ever pushed with an unscanned or vulnerable build. No deployment happens without a corresponding Git commit.

---

## Known limitations (local Kind environment)

- Kind cannot natively pull from private ECR (no IAM role support) — images are loaded manually via `kind load docker-image` for local testing. This is a Kind-specific limitation, not a pipeline issue.
- Full end-to-end GitOps validation (ECR → ArgoCD → cluster, with zero manual steps) is performed on AWS EKS where IAM roles for service accounts (IRSA) handle registry auth natively.

---

## Roadmap

- [x] Custom Docker images for all services
- [x] Terraform-managed AWS infrastructure (VPC, ECR)
- [x] Kubernetes manifests + Helm chart
- [x] CI/CD with Trivy security scanning
- [x] ArgoCD GitOps
- [x] Prometheus + Grafana observability
- [ ] Horizontal Pod Autoscaling (HPA) under simulated load
- [ ] Nginx reverse proxy / ingress
- [ ] AWS Secrets Manager integration
- [ ] Uptime Kuma status page
- [ ] Full deployment validation on AWS EKS

---

## Author

**Abdul Manan Ali**
Lahore, Pakistan — transitioning into DevOps
[GitHub](https://github.com/abdulmanan-ali)

---

## License

Original sample application licensed under MIT-0 by Amazon.com, Inc. See [LICENSE](./LICENSE).
DevOps platform code in `devops/` is original work by the author.