variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster"
  type        = string
}

variable "ebs_csi_addon_version" {
  description = "Version of the EBS CSI driver addon to use"
  type        = string
  default     = "v1.40.1-eksbuild.1"
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for EBS volumes"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for EBS volume encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to resources"
  type        = map(string)
  default     = {}
}