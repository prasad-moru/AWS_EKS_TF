variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "StoreApp-Project"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
  validation {
    condition     = var.availability_zones_count >= 2
    error_message = "At least 2 AZs are required for high availability."
  }
}

variable "subnet_cidr_bits" {
  description = "Number of bits to use for subnet CIDR blocks"
  type        = number
  default     = 8
}

# EKS Configuration
variable "eks_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for EKS node groups"
  type        = list(string)
  default     = ["c5.xlarge"]
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 4
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "eks_node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

# ALB Ingress Controller
variable "enable_alb_ingress" {
  description = "Enable ALB Ingress Controller"
  type        = bool
  default     = true
}

# Tags
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    "Project"     = "StoreApp-Project"
    "Environment" = "Development"
    "Terraform"   = "true"
    "Owner"       = "DevOps"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_cloudwatch_agent" {
  description = "Enable CloudWatch agent on nodes for enhanced monitoring"
  type        = bool
  default     = false
}