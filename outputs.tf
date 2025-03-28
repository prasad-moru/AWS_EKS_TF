# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# EKS Outputs
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "node_group_name" {
  description = "The name of the EKS node group"
  value       = module.eks.node_group_name
}

# EBS CSI Driver Outputs
output "ebs_csi_role_arn" {
  description = "ARN of IAM role for EBS CSI driver"
  value       = module.ebs_csi.ebs_csi_role_arn
}

# ALB Ingress Controller Outputs
output "alb_ingress_role_arn" {
  description = "ARN of IAM role for ALB Ingress Controller"
  value       = var.enable_alb_ingress ? module.alb_ingress[0].alb_ingress_role_arn : null
}

# Command to update kubeconfig
output "configure_kubectl" {
  description = "Command to configure kubectl to connect to the EKS cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}