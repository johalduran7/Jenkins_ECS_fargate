variable "path_user_data" {
  type    = string
  default = "./modules/ec2_master/user_data.sh"
}

variable "env" {
  type    = string
  default = "jenkins"
}

variable "aws_region" {
  description = "The AWS region to create resources in"
  default     = "us-east-1"
}

variable "jenkins_ecr_repository_url" {
  type    = string
  default = ""
}
variable "vpc_id" {
  type    = string
  default = "vpc-53cd6b2e"
}

variable "ssh_public_key" {
  type    = string
  default = "key_saa.pub"
}

variable "s3_bucket_name" {
  type    = string
  default = "fargate-jenkins-john-duran"
}

variable "aws_s3_bucket_arn" {
  type    = string
  default = ""
}
variable "jenkins_volume_id" {
  type    = string
  default = ""
}
