resource "aws_ecr_repository" "ecr_repo" {
  name = var.name

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256" # default encryption at rest
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}
