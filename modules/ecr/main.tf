resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.env_prefix}-app-repo"
  image_tag_mutability = "MUTABLE"

  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true # Good for security!
  }
}

# This deletes old images so you don't pay for 100 versions of "v1-old"
resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = { type = "expire" 
      }

      rulePriority = 2
        description  = "Delete untagged images (failed builds) after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
    }]
  })
}