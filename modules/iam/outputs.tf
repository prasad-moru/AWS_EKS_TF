output "cluster_role_arn" {
  description = "The ARN of the IAM role for the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "The ARN of the IAM role for EKS nodes"
  value       = aws_iam_role.node.arn
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.url
}