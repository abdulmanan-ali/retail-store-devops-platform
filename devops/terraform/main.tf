provider "aws" {
  region = var.aws-region

default_tags {
    tags = {
        Environment = var.environment
        Project     = "retail-store-devops"
        ManagedBy   = "Terraform"
        Owner       = "abdulmanan-ali"
    }
}
}
