# For development environment (in environments/development/backend.tf)
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "environments/development/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
