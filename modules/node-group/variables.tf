variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  type        = string
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["c5.xlarge"]
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}