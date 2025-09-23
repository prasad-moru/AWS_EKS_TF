output "repository_url" {
  description = "URL of the created ECR repo"
  value       = aws_ecr_repository.ecr_repo.repository_url
}
