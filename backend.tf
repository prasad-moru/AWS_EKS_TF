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

# For staging environment (in environments/staging/backend.tf)
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "environments/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# For production environment (in environments/production/backend.tf)
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "environments/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}