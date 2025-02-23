# AWS Region
variable "aws_region" {
  description = "The AWS region to create resources in"
  default     = "us-east-1"
}

variable "ecr_repo_name" {
  type    = string
  default = "jenkins"
}

variable "s3_bucket_name" {
  type    = string
  default = "fargate-jenkins-john-duran"
}

variable "env" {
  type    = string
  default = "jenkins"
}

# VPC CIDR Block
variable "cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}


# VPC Name Tag
variable "vpc_name" {
  description = "The name tag for the VPC"
  default     = "app-vpc"
}

# Public Subnet A
variable "public_subnet_a_cidr" {
  description = "CIDR block for Public Subnet A"
  default     = "10.0.0.0/24"
}

variable "public_subnet_a_name" {
  description = "Name tag for Public Subnet A"
  default     = "PublicSubnetA"
}

# Public Subnet B
variable "public_subnet_b_cidr" {
  description = "CIDR block for Public Subnet B"
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_name" {
  description = "Name tag for Public Subnet B"
  default     = "PublicSubnetB"
}

# Private Subnet A
variable "private_subnet_a_cidr" {
  description = "CIDR block for Private Subnet A"
  default     = "10.0.16.0/20"
}

variable "private_subnet_a_name" {
  description = "Name tag for Private Subnet A"
  default     = "PrivateSubnetA"
}

# Private Subnet B
variable "private_subnet_b_cidr" {
  description = "CIDR block for Private Subnet B"
  default     = "10.0.32.0/20"
}

variable "private_subnet_b_name" {
  description = "Name tag for Private Subnet B"
  default     = "PrivateSubnetB"
}