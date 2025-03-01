##### For troubleshooting
# resource "aws_ecs_task_definition" "ubuntu_debug" {
#   family                   = "ubuntu-debug-task"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "512"
#   memory                   = "1024"
#   execution_role_arn = aws_iam_role.ecs_task_execution_role_slave_jenkins.arn # Ensure this role is created elsewhere
#   task_role_arn      = aws_iam_role.ecs_task_role_slave_jenkins.arn      # Ensure this role is created elsewhere

#   container_definitions = jsonencode([
#     {
#       name      = "ubuntu-container"
#       image     = "ubuntu:latest"
#       essential = true
#       command   = ["sleep", "3600"]


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
#           awslogs-region        = var.aws_region
#           awslogs-stream-prefix = "jenkins-ubuntus-container" #"${aws_cloudwatch_log_stream.ecs_log_stream.name}"
#         }
#       }
#     }

#   ])


#   tags = {
#     Name      = "Jenkins UBUNTU Fargate Task"
#     Terraform = "yes"
#   }

# }

resource "aws_ecs_task_definition" "jenkins_slave_fargate_task_test" {
  family                   = "${var.jenkins_cloud_name}-test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"



  # you can define up to 10 containers per task definition
  container_definitions = jsonencode([{
    name      = "jenkins-slave-test"
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
    entryPoint = ["/bin/sh", "-c"]
    command   = ["while true; do sleep 30; done"]
    

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_cluster_cloudwatch.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "jenkins-agent-container-test" #"${aws_cloudwatch_log_stream.ecs_log_stream.name}"
      }
    }

  }])




  execution_role_arn = aws_iam_role.ecs_task_execution_role_slave_jenkins.arn # Ensure this role is created elsewhere
  task_role_arn      = aws_iam_role.ecs_task_role_slave_jenkins.arn           # Ensure this role is created elsewhere

  tags = {
    Name      = "Jenkins Slaves Fargate Task test"
    Terraform = "yes"
  }
}



# # # 5. Optional: ECS Service to run the Fargate Task
resource "aws_ecs_service" "fargate_service" {
  name                   = "jenkins_fargate_service_test"
  cluster                = aws_ecs_cluster.jenkins_cluster.id
  task_definition        = aws_ecs_task_definition.jenkins_slave_fargate_task_test.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true # this is needed to run $ aws ecs execute-command

  network_configuration {
    subnets          = toset(data.aws_subnets.subnets.ids)
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }



  tags = {
    Name      = "JenkinsFargateService_test"
    Terraform = "yes"
  }
}

