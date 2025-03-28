variable "name" {
  description = "Name prefix for VPC resources"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "subnet_cidr_bits" {
  description = "Number of bits to use for subnet CIDR blocks"
  type        = number
  default     = 8
}

variable "cluster_name" {
  description = "Name of the EKS cluster for tagging"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to VPC resources"
  type        = map(string)
  default     = {}
}