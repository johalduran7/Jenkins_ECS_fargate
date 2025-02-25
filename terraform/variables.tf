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

###### ECS Cloud/Node configuration if ECS plugin installed
# if you want to use the default ECS node, create a cloude/node with an ECS agent template label called as follows on Jenkins, the following instances will
# automatically pick up the values for: task_definition,subnet_id,SG_i,TaskRole,ExecutionRole,Cluster,Region. If not, you have to
# manually configure the template and update the values for subnet_id and sg_id if  you destroy those resources at some point. 
# Ideally, you don't have to destroy those resources if you don't use Jenkins.
variable "jenkins_cloud_name" {
  type    = string
  default = "ecs_fargate_slaves_default"
}
######

##### VPN Configuration ####
## If vpc_type set to default, the infrastructure will be deployed in the default vpc and public subnets of the current region.
## if vpc type set to custom, you have to define the CIDS and values for your vpc.
## If the secure variable is set to true, a NAT gateway will be deployed and you will be able to access 
## Jenkins GUI via SSM (The URL will be prompted), bear in mind that NAT will incur in more expenses.
## if secure is set to false, the infrastructure will be deployed on AZ A in public subnets.
## The intention of this deployment is to automate Jenkins, not to make it High Available, actually, the ec2 instances
## and the fargate tasks are Spot.
# VPC CIDR Block

variable "vpc_type" {
  description = "if Default -> Default vpc. If custom -> defined CIDRS and VPC values"
  default     = "default"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}


# VPC Name Tag
variable "vpc_name" {
  description = "The name tag for the VPC"
  default     = "app-vpc"
}

variable "secure" {
  description = "Private (+ NAT) or Public Subnets"
  default     = "false"
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

# Private Subnet A
variable "private_subnet_a_cidr" {
  description = "CIDR block for Private Subnet A"
  default     = "10.0.16.0/20"
}

variable "private_subnet_a_name" {
  description = "Name tag for Private Subnet A"
  default     = "PrivateSubnetA"
}
