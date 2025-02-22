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

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   from_port   = 8080
  #   to_port     = 8080
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   from_port   = 50000
  #   to_port     = 50000
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
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
  family                   = "jenkins_master_fargate_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"

  #   runtime_platform {
  #     operating_system_family = "LINUX"
  #     cpu_architecture        = "X86_64"
  #   }

  # you can define up to 10 containers per task definition
  container_definitions = jsonencode([{
    name       = "jenkins-agent"
    image      = "jenkins/inbound-agent"
    cpu        = 1024
    memory     = 2048
    essential  = true
    entryPoint = ["java", "-jar", "/usr/share/jenkins/agent.jar"]


    environment = [
      { "name" : "JENKINS_URL", "value" : "${var.JENKINS_URL}" },
      { "name" : "JENKINS_AGENT_NAME", "value" : "${var.JENKINS_AGENT_NAME}" }
      #,
      #{ "name" : "JENKINS_SECRET", "value" : "${var.JENKINS_SECRET}" } # Inject securely
    ]
    # This command ensures the agent registers correctly with Jenkins
    command = [
      "-workDir", "/home/jenkins",
      "-url", "${var.JENKINS_URL}",
      #"-name", "fargate-agent",
      #"${var.JENKINS_AGENT_NAME}"
      "-webSocket"
    ]
    # # Health Check to verify agent registration with Jenkins master
    # healthCheck = {
    #   command     = ["CMD-SHELL", "wget -q --spider ${var.JENKINS_URL}/computer/fargate-agent/api/json || exit 1"]
    #   interval    = 60 # Run health check every 60s
    #   timeout     = 10 # Timeout after 10s
    #   retries     = 3  # Retry 3 times before marking unhealthy
    #   startPeriod = 30 # Wait 30s before starting health checks
    # }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_cluster_cloudwatch.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "jenkins-agent-container" #"${aws_cloudwatch_log_stream.ecs_log_stream.name}"
      }
    }

  }])



  execution_role_arn = aws_iam_role.ecs_execution_role.arn # Ensure this role is created elsewhere
  task_role_arn      = aws_iam_role.ecs_task_role.arn      # Ensure this role is created elsewhere

  tags = {
    Name      = "Jenkins Slaves Fargate Task"
    Terraform = "yes"
  }
}

# resource "aws_ecs_task_definition" "hello_world" {
#   family                   = "hello-world-task"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "256"
#   memory                   = "512"

#   container_definitions = jsonencode([
#     {
#       name      = "hello-world"
#       image     = "nginx:latest"
#       cpu       = 256
#       memory    = 512
#       essential = true

#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#           protocol      = "tcp"
#         }
#       ]

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.ecs_cluster_cloudwatch.name
#           awslogs-region        = "us-east-1"
#           awslogs-stream-prefix = "hello-world"#"${aws_cloudwatch_log_stream.ecs_log_stream.name}"
#         }
#       }
#     }
#   ])

#   execution_role_arn = aws_iam_role.ecs_execution_role.arn
#   task_role_arn      = aws_iam_role.ecs_task_role.arn
# }



# 5. Optional: ECS Service to run the Fargate Task
resource "aws_ecs_service" "fargate_service" {
  name                   = "jenkins_fargate_service"
  cluster                = aws_ecs_cluster.jenkins_cluster.id
  task_definition        = aws_ecs_task_definition.hello_world.arn
  desired_count          = 0
  launch_type            = "FARGATE"
  enable_execute_command = true # this is needed to run $ aws ecs execute-command

  network_configuration {
    subnets          = toset(data.aws_subnets.subnets.ids)
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }



  tags = {
    Name      = "JenkinsFargateService"
    Terraform = "yes"
  }
}


