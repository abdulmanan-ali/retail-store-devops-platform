output "ecr_repository_urls" {
    description = "Map of ECR repository names to their URLs"
    value = {for name, repo in aws_ecr_repository.services : name => repo.repository_url}
}

output "vpc_id" {
    description = "The ID of the VPC"
    value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "eks_cluster_name" {
    description = "The name of the EKS cluster"
    value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
    description = "The endpoint of the EKS cluster"
    value = module.eks.cluster_endpoint
}

