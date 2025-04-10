variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "cluster_identity_oidc_issuer" {
  description = "The OIDC Identity issuer for the cluster"
  type        = string
}

variable "enable_cloudwatch_agent" {
  description = "Enable CloudWatch agent on nodes"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}