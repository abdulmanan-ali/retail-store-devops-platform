module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project-name}-eks"
  kubernetes_version = "1.33"

  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.private_subnets}"

  eks_managed_node_groups = {
    general = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types   = ["t3.medium"]
    }
  }

}