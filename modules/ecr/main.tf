resource "aws_ecr_repository" "ecr_repo" {
  name = var.name

  image_tag_mutability = var.image_tag_mutability

  encryption_configuration {
    encryption_type = var.encryption_type
  }

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}

# Lifecycle policy to manage images
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_count_to_keep} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_count_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Repository policy to allow EKS nodes to pull images
resource "aws_ecr_repository_policy" "ecr_policy" {
  count      = var.node_role_arn != null ? 1 : 0
  repository = aws_ecr_repository.ecr_repo.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodesToPull"
        Effect = "Allow"
        Principal = {
          AWS = var.node_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
      }
    ]
  })
}