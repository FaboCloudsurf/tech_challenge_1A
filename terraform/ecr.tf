# This creates a private place in AWS to store the frontend Docker images (like a private Docker Hub).
resource "aws_ecr_repository" "frontend_repo" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"          # Allows you to overwrite an image tag with a newer version

  image_scanning_configuration {
    scan_on_push = true                     # Automatically checks every new image for security problems
  }

   tags = {
    Name        = "${var.project_name}-frontend-repo"
    Environment = var.environment
    }
}


# Backend container image storage
# Same as above, but this one stores the backend Docker images.
resource "aws_ecr_repository" "backend_repo" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

   tags = {
    Name        = "${var.project_name}-backend-repo"
    Environment = var.environment
    }
}


# Automatic cleanup for frontend images
# This rule automatically deletes old frontend images so the repository doesn’t keep growing forever.
# It keeps only the 5 most recent images whose tags start with "v" (for example v1.0, v1.1, etc.).
resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend_repo.name

  policy = jsonencode({

    rules = [
    {
      rulePriority = 1
      description = "Keep last 5 images"
      selection = {
        tagStatus = "tagged"
        tagPrefixList = ["v"]
        countType = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"                       # Delete the older images
        }
      }
    ]
  })
}  
   
  

resource "aws_ecr_lifecycle_policy" "backed" {
  repository = aws_ecr_repository.backend_repo.name

 policy = jsonencode({

    rules = [
    {
      rulePriority = 1
      description = "Keep last 5 images"
      selection = {
        tagStatus = "tagged"
        tagPrefixList = ["v"]
        countType = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
        }
      }
    ]
  })
} 