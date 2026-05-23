variable "aws-region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project-name" {
  description = "Name of the project"
  type        = string
  default     = "retail-store"
}