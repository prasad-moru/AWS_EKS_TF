output "repository_url" {
  description = "URL of the created ECR repo"
  value       = aws_ecr_repository.ecr_repo.repository_url
}

output "repository_arn" {
  description = "ARN of the created ECR repo"
  value       = aws_ecr_repository.ecr_repo.arn
}

output "repository_name" {
  description = "Name of the created ECR repo"
  value       = aws_ecr_repository.ecr_repo.name
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.ecr_repo.registry_id
}