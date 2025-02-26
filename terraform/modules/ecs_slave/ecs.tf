data "aws_caller_identity" "current" {}

# this is needed for aws ecs execute-command
resource "aws_cloudwatch_log_group" "ecs_cluster_cloudwatch" {
  name              = "/ecs/jenkins"
  retention_in_days = 1 # Retain logs for x days
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}


resource "aws_ecs_cluster" "jenkins_cluster" {
  name = var.cluster_name

  # this is needed for aws ecs execute-command. See if it's enabled aws ecs describe-clusters --clusters JenkinsCluster --output json

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_cluster_cloudwatch.name
      }
    }
  }

  tags = {
    Terraform = "yes"
  }
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.env}-sg_ecs_cluster_slaves"
  vpc_id = var.vpc_id # Ensure to provide the VPC ID in the variables
  # Jenkins master access through AWS CLI, no need ingress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.env}-sg_ecs_cluster_slaves"
    Terraform = "yes"
  }
}



resource "aws_ecs_task_definition" "jenkins_slave_fargate_task" {
  family                   = var.jenkins_cloud_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"


  # you can define up to 10 containers per task definition
  container_definitions = jsonencode([{
    name      = "jenkins-slave"
    image     = "${var.jenkins_slave_repository_url}:latest"
    cpu       = 1024
    memory    = 2048
    essential = true

    portMappings = [
      {
        containerPort = 8080
        hostPort      = 8080
        protocol      = "tcp"
      }
    ]
    portMappings = [
      {
        containerPort = 50000
        hostPort      = 50000
        protocol      = "tcp"
      }
    ]
    environment = [
      { "name" : "workDir", "value" : "/home/jenkins" }

    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_cluster_cloudwatch.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "jenkins-agent-container" #"${aws_cloudwatch_log_stream.ecs_log_stream.name}"
      }
    }

  }])



  execution_role_arn = aws_iam_role.ecs_task_execution_role_slave_jenkins.arn # Ensure this role is created elsewhere
  task_role_arn      = aws_iam_role.ecs_task_role_slave_jenkins.arn           # Ensure this role is created elsewhere

  tags = {
    Name      = "Jenkins Slaves Fargate Task"
    Terraform = "yes"
  }
}

