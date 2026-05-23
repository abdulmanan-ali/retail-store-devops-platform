terraform {
    backend "s3" {
        bucket = "retail-store-devops-tfstate-866849310135"
        key = "retail-store/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "retail-store-terraform-locks"
        encrypt = true
    }
}