# AWS EKS Infrastructure with Terraform

This repository contains Terraform code for deploying a production-ready Amazon EKS (Elastic Kubernetes Service) cluster with all necessary supporting infrastructure.

## Architecture Overview

The infrastructure is built using a modular approach with the following components:

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                               AWS VPC                               │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────┐  │
│  │             │   │             │   │             │   │         │  │
│  │ Public      │   │ Public      │   │ Private     │   │ Private │  │
│  │ Subnet (AZ1)│   │ Subnet (AZ2)│   │ Subnet (AZ1)│   │ Subnet  │  │
│  │             │   │             │   │             │   │ (AZ2)   │  │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────┘  │
│         │                 │                 │               │       │
│         │                 │                 │               │       │
│         ▼                 ▼                 │               │       │
│  ┌─────────────────────────────┐            │               │       │
│  │                             │            │               │       │
│  │      Internet Gateway       │            │               │       │
│  │                             │            │               │       │
│  └─────────────┬───────────────┘            │               │       │
│                │                            │               │       │
│                ▼                            │               │       │
│  ┌─────────────────────────────┐            │               │       │
│  │                             │            │               │       │
│  │        NAT Gateway          │            │               │       │
│  │                             │            │               │       │
│  └─────────────┬───────────────┘            │               │       │
│                │                            │               │       │
│                └────────────────────────────┼───────────────┘       │
│                                             │                       │
│                                             ▼                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │                     EKS Cluster                               │  │
│  │                                                               │  │
│  │   ┌─────────────────────────┐      ┌────────────────────────┐ │  │
│  │   │                         │      │                        │ │  │
│  │   │  Control Plane          │      │  Node Group            │ │  │
│  │   │                         │      │  (in private subnets)  │ │  │
│  │   └─────────────────────────┘      └────────────────────────┘ │  │
│  │                                                               │  │
│  │   ┌─────────────────────────┐      ┌────────────────────────┐ │  │
│  │   │                         │      │                        │ │  │
│  │   │  EBS CSI Driver         │      │  ALB Ingress Controller│ │  │
│  │   │                         │      │                        │ │  │
│  │   └─────────────────────────┘      └────────────────────────┘ │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
.
├── .gitignore
├── README.md
├── backend.tf
├── main.tf                  # Main entry point that calls all modules
├── outputs.tf               # Output values from all modules
├── providers.tf             # Provider configurations
├── variables.tf             # Variable definitions
├── modules/
│   ├── vpc/                 # VPC module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── eks/                 # EKS module
│   │   ├── iam.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── ebs-csi/             # EBS CSI Driver module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── alb-ingress/         # ALB Ingress Controller module
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
```

## Module Overview

```

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```  


### VPC Module

Creates a VPC with public and private subnets across multiple availability zones, with internet gateway, NAT gateway, and appropriate route tables.

Key components:
- VPC with CIDR block (default: 10.0.0.0/16)
- Public subnets with internet access
- Private subnets with NAT gateway access
- Properly tagged subnets for EKS and ALB Ingress Controller

### EKS Module

Deploys an Amazon EKS cluster with a managed node group and all necessary IAM roles and security groups.

Key components:
- EKS cluster with specified Kubernetes version
- Node group with customizable instance types and scaling configuration
- IAM roles for cluster and node group
- Security groups for cluster and node communication
- OIDC provider for service account federation

### EBS CSI Driver Module

Installs the EBS CSI Driver as an EKS add-on to enable persistent storage for Kubernetes workloads.

Key components:
- EBS CSI Driver EKS add-on
- IAM role with permissions for the EBS CSI Driver
- Optional KMS encryption support

### ALB Ingress Controller Module

Deploys the AWS Load Balancer Controller using Helm to enable Application Load Balancer (ALB) support for Kubernetes Ingress resources.

Key components:
- AWS Load Balancer Controller Helm chart
- IAM role with necessary permissions
- IngressClass configuration
- Optional WAF and Shield integration

## Configuration Details

### VPC Configuration
- **VPC Name**: "${var.project}-${var.environment}-vpc" (e.g., "TFEKSWorkshop-dev-vpc")
- **VPC CIDR**: 10.0.0.0/16 (configurable via var.vpc_cidr)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

#### Subnet Configuration
- **Availability Zones**: First 2 AZs in the region (configurable, minimum 2)
- **Public Subnets CIDR Blocks**: 
  - First AZ: 10.0.0.0/24
  - Second AZ: 10.0.1.0/24
- **Private Subnets CIDR Blocks**:
  - First AZ: 10.0.2.0/24
  - Second AZ: 10.0.3.0/24

### EKS Cluster Configuration
- **Cluster Name**: "${var.project}-${var.environment}-cluster" (e.g., "TFEKSWorkshop-dev-cluster")
- **Kubernetes Version**: 1.29 (configurable via var.eks_version)
- **API Server Endpoint Access**: Both private and public
- **Add-ons**: CoreDNS, kube-proxy, vpc-cni

#### Node Group Configuration
- **Node Group Name**: "${var.project}-${var.environment}-nodes" (e.g., "TFEKSWorkshop-dev-nodes")
- **Instance Types**: ["t3.medium"] (configurable via var.eks_node_instance_types)
- **AMI Type**: AL2_x86_64
- **Capacity Type**: ON_DEMAND
- **Disk Size**: 20 GB (configurable via var.eks_node_disk_size)
- **Scaling Configuration**:
  - Desired: 2 (configurable via var.eks_node_desired_size)
  - Min: 1 (configurable via var.eks_node_min_size)
  - Max: 4 (configurable via var.eks_node_max_size)

### Security Groups

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  Cluster Security Group                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Inbound:                                                │   │
│  │ - 443/TCP from 0.0.0.0/0 (API server access)           │   │
│  │ - 443/TCP from Node Security Group                      │   │
│  │                                                         │   │
│  │ Outbound:                                               │   │
│  │ - All traffic to 0.0.0.0/0                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Node Security Group                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Inbound:                                                │   │
│  │ - All traffic from other nodes in the same group        │   │
│  │ - 1025-65535/TCP from Cluster Security Group            │   │
│  │                                                         │   │
│  │ Outbound:                                               │   │
│  │ - All traffic to 0.0.0.0/0                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### IAM Roles and Policies

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  EKS Cluster Role                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ - AmazonEKSClusterPolicy                               │   │
│  │ - AmazonEKSVPCResourceController                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Node Role                                                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ - AmazonEKSWorkerNodePolicy                            │   │
│  │ - AmazonEKS_CNI_Policy                                 │   │
│  │ - AmazonEC2ContainerRegistryReadOnly                   │   │
│  │ - AmazonSSMManagedInstanceCore                         │   │
│  │ - CloudWatchAgentServerPolicy (optional)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  EBS CSI Driver Role                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ - AmazonEBSCSIDriverPolicy                             │   │
│  │ - KMS encryption policy (optional)                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ALB Controller Role                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ - Custom policy for ALB management                      │   │
│  │ - EC2 network resources                                 │   │
│  │ - Elastic Load Balancers                               │   │
│  │ - WAF and Shield integration (optional)                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform v1.1.0 or newer
- kubectl installed locally (for cluster access)

### Deployment Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/prasad-moru/AWS_EKS_TF.git
   cd <repository-directory>
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Create a `terraform.tfvars` file with your specific .values:
   ```hcl
   aws_access_key = "your-access-key"
   aws_secret_key = "your-secret-key"
   region         = "us-east-1"
   project        = "YourProject"
   environment    = "dev"
   ```

4. Plan and apply the infrastructure:
   ```bash
   terraform plan
   terraform apply
   ```

5. Configure kubectl to connect to your new EKS cluster:
   ```bash
   aws eks update-kubeconfig --name <cluster-name> --region <region>
   ```

6. Verify the cluster is working:
   ```bash
   kubectl get nodes
   ```

## Resource Tagging Strategy

All resources are tagged with the following default tags:
- `Project`: "TFEKSWorkshop" (configurable)
- `Environment`: "Development" (configurable)
- `Terraform`: "true"
- `Owner`: "DevOps"

Additional tags can be supplied via the `var.additional_tags` variable.

## Security Best Practices

This infrastructure follows AWS security best practices:

1. **Networking**: Uses a VPC with private subnets for node groups, with NAT gateway for outbound internet access
2. **IAM**: Uses least-privilege IAM roles for all components
3. **API Server**: Allows configurable public/private endpoint access
4. **Node Security**: Nodes deployed in private subnets with proper security groups
5. **Service Account Access**: Uses OIDC provider for fine-grained pod-level permissions

## Maintenance and Operations

### Updating the Cluster

To update the Kubernetes version:

1. Update the `eks_version` variable
2. Run `terraform plan` and `terraform apply`

### Scaling the Cluster

To scale the node group:

1. Update the following variables:
   - `eks_node_desired_size`
   - `eks_node_min_size`
   - `eks_node_max_size`
2. Run `terraform plan` and `terraform apply`

## Troubleshooting

Common issues and their solutions:

1. **Terraform fails to create EKS cluster**:
   - Ensure IAM permissions are correct
   - Check VPC subnet configurations

2. **Nodes fail to join the cluster**:
   - Verify security group rules
   - Check subnet tags

3. **ALB Ingress Controller issues**:
   - Ensure subnet tagging is correct
   - Verify the IAM role has proper permissions

## Contributing

Contributions to improve the infrastructure are welcome. Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
