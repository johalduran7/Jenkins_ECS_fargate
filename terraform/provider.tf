
terraform {
  backend "s3" {
    bucket         = "jenkins-terraform-backend-john-duran"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jenkins_terraform_backend"
    encrypt        = true
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}