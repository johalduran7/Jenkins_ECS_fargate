variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "jenkins"
}

variable "cluster_name" {
  type    = string
  default = "JenkinsCluster"
}

variable "vpc_id" {
  type    = string
  default = "vpc-53cd6b2e"
}

variable "JENKINS_URL" {
  type    = string
  default = "https://1fbb-206-84-81-148.ngrok-free.app"
}

variable "JENKINS_SECRET" {
  type    = string
  default = ""
}

variable "JENKINS_AGENT_NAME" {
  type    = string
  default = "ecs"
}

variable "jenkins_cloud_name" {
  type    = string
  default = ""
}
