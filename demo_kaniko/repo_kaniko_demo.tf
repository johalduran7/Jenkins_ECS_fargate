provider "aws" {
  region = "us-east-1"
}

# Repository created for the pipeline to push the image of the app
resource "aws_ecr_repository" "kaniko_demo" {
  name                 = "kaniko_demo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_kaniko_demo_policy" {
  repository = aws_ecr_repository.kaniko_demo.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only the latest two images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}