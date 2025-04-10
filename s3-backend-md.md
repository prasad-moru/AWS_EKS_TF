# Terraform S3 Backend Configuration

This guide explains how to set up and use an S3 backend with DynamoDB state locking for your Terraform AWS EKS project.

## S3 Backend Configuration

Create a file named `backend.tf` in your project root:

```terraform
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Environment-Specific Configurations

For different environments, use separate state files:

### Development Environment

File: `environments/development/backend.tf`

```terraform
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "environments/development/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Staging Environment

File: `environments/staging/backend.tf`

```terraform
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "environments/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Production Environment

File: `environments/production/backend.tf`

```terraform
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "environments/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Setup Prerequisites

Before using the S3 backend, you need to create the necessary AWS resources:

### 1. Create the S3 Bucket

```bash
# Create bucket
aws s3api create-bucket --bucket aws-eks-tt-automation --region us-east-1

# Enable versioning (recommended)
aws s3api put-bucket-versioning --bucket aws-eks-tt-automation --versioning-configuration Status=Enabled

# Enable encryption (optional but recommended)
aws s3api put-bucket-encryption --bucket aws-eks-tt-automation --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'
```

### 2. Create the DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 3. Initialize Terraform with the Backend

```bash
# For new projects
terraform init

# For existing projects migrating from local state
terraform init -migrate-state
```

## Benefits of S3 Backend

- **Team Collaboration**: Multiple team members can work on the same infrastructure
- **State Durability**: State is safely stored in S3 with versioning
- **State Locking**: Prevents concurrent modifications with DynamoDB
- **Security**: State file is encrypted at rest
- **Separation of Concerns**: Different environments can use different state files

## Important Considerations

- Ensure all team members have appropriate IAM permissions to access the S3 bucket and DynamoDB table
- Consider using different S3 buckets for different environments in highly secure setups
- Remember to destroy resources when they are no longer needed

## Examples of Backend Usage

### Partial Backend Configuration

You can use variables in your backend configuration by creating a file (e.g., `backend.conf`):

```hcl
region         = "us-east-1"
bucket         = "aws-eks-tt-automation"
key            = "terraform.tfstate"
dynamodb_table = "terraform-state-lock"
encrypt        = true
```

Then initialize with:

```bash
terraform init -backend-config=backend.conf
```

### Workspace-Aware Configuration

If you're using Terraform workspaces:

```terraform
terraform {
  backend "s3" {
    bucket         = "aws-eks-tt-automation"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    workspace_key_prefix = "workspaces"
  }
}
```

This will store state files at `workspaces/WORKSPACE_NAME/terraform.tfstate`
