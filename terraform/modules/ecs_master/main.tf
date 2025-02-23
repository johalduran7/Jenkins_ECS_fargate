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
  name   = "ecs_cluster_sg"
  vpc_id = var.vpc_id # Ensure to provide the VPC ID in the variables

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "ECS Cluster SG"
    Terraform = "yes"
  }
}



resource "aws_ecs_task_definition" "jenkins_master_fargate_task" {
  family                   = "jenkins_master"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"


  # you can define up to 10 containers per task definition
  container_definitions = jsonencode([{
    name      = "jenkins-master"
    image     = "${var.jenkins_ecr_repository_url}:latest"
    cpu       = 1024
    memory    = 2048
    essential = true

    portMappings = [
      {
        containerPort = 8080
        hostPort      = 8080
      },
      {
        containerPort = 50000
        hostPort      = 50000
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_cluster_cloudwatch.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "jenkins-master" #"${aws_cloudwatch_log_stream.ecs_log_stream.name}"
      }
    }
    environment = [
      { name = "JENKINS_HOME", value = "/var/jenkins_home" }
    ]
    # mountPoints = [
    #   {
    #     sourceVolume  = "jenkins-data"
    #     containerPath = "/var/jenkins_home"
    #   }
    # ]
    # command = [
    #   "/bin/sh", "-c", <<EOT
    #   set -e  # Stop on first error
    #   sudo rm -rf /var/jenkins_home

    #   echo "⏳ Finding latest backup..."
    #   LATEST_BACKUP=$(aws s3 ls s3://${var.s3_bucket_name}/ | grep 'jenkins_volume_backup_' | sort | tail -n 1 | awk '{print $4}')

    #   if [ -z "$LATEST_BACKUP" ]; then
    #     echo "⚠️ No backup found. Starting Jenkins without restore."
    #   else
    #     echo "📂 Latest backup: $LATEST_BACKUP"
    #     aws s3 cp s3://${var.s3_bucket_name}/$LATEST_BACKUP /tmp/backup.tar.gz

    #     echo "📦 Extracting backup..."
    #     mkdir -p /var/jenkins_home
    #     sudo tar -xzf /tmp/backup.tar.gz -C /var/jenkins_home

    #     echo "🔧 Fixing permissions..."
    #     sudo chown -R jenkins:jenkins /var/jenkins_home

    #     echo "✅ Backup restored successfully."
    #   fi
    #   EOT
    # ]


  }])



  execution_role_arn = aws_iam_role.ecs_task_execution_role_master_jenkins.arn # Ensure this role is created elsewhere
  task_role_arn      = aws_iam_role.ecs_task_role_master_jenkins.arn           # Ensure this role is created elsewhere

  tags = {
    Name      = "Jenkins Master Fargate Task"
    Terraform = "yes"
  }
}


# 5. Optional: ECS Service to run the Fargate Task
resource "aws_ecs_service" "jenkins_master_service" {
  name                   = "jenkins_master_service"
  cluster                = aws_ecs_cluster.jenkins_cluster.id
  task_definition        = aws_ecs_task_definition.jenkins_master_fargate_task.arn
  desired_count          = 0
  launch_type            = "FARGATE"
  enable_execute_command = true # this is needed to run $ aws ecs execute-command

  lifecycle {
    ignore_changes = [desired_count] # it prevents the value from being updated after the first run of Terraform.
  }

  network_configuration {
    subnets          = toset(data.aws_subnets.subnets.ids)
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }



  tags = {
    Name      = "JenkinsMasterFargateService"
    Terraform = "yes"
  }
}


