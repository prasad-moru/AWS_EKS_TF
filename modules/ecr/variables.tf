variable "name" {
  description = "ECR repository name"
  type        = string
}

variable "tags" {
  description = "Tags for ECR repository"
  type        = map(string)
  default     = {}
}
