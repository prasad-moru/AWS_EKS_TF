output "repository_urls" {
  description = "The URLs of the created ECR repositories"
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  description = "The ARNs of the created ECR repositories"
  value       = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}

output "repository_names" {
  description = "The names of the created ECR repositories"
  value       = var.repository_names
}