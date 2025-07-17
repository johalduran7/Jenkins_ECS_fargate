resource "aws_ecr_repository" "jenkins_slave" {
  name                 = "${var.ecr_repo_name}-slave"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecr_lifecycle_policy" "ecr_jenkins_policy_slave" {
  repository = aws_ecr_repository.jenkins_slave.name

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


# Null resource to build and push the Docker image
resource "null_resource" "build_and_push_slave_image" {
  triggers = {
    # Rebuild the image if the Dockerfile changes
    dockerfile_hash = filemd5("${path.module}/Dockerfile")
  }

  provisioner "local-exec" {
    command = <<EOT
      # Authenticate Docker to ECR
      set -e
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.jenkins_slave.repository_url}

      #docker build --no-cache -t ${var.ecr_repo_name}:latest ${path.module}
      
      # Build the Docker image
      docker build --no-cache -t ${aws_ecr_repository.jenkins_slave.repository_url}:latest ${path.module}

      # Push the Docker image to ECR
      docker push ${aws_ecr_repository.jenkins_slave.repository_url}:latest
    EOT
  }

}