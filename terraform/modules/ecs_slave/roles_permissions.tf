# ecs_task_execution role to allow the ecs agent to pull from ECR, etc
resource "aws_iam_role" "ecs_task_execution_role_slave_jenkins" {
  name = "ecs_task_execution_role_slave_jenkins"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Terraform = "yes"
    aws_saa   = "yes"
  }
}

resource "aws_iam_policy_attachment" "ecs_execution_role_policy_attachment" {
  name       = "ecs_execution_role_policy_attachment"
  roles      = [aws_iam_role.ecs_task_execution_role_slave_jenkins.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# Add CloudWatch logging permissions to Execution Role
resource "aws_iam_policy" "ecs_execution_logging_policy_slave_jenkins" {
  name        = "ecs_execution_logging_policy_slave_jenkins"
  description = "Allows ECS task execution to write logs to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.ecs_cluster_cloudwatch.arn}:*"
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_logging_attachment" {
  name       = "ecs_execution_logging_attachment"
  roles      = [aws_iam_role.ecs_task_execution_role_slave_jenkins.name]
  policy_arn = aws_iam_policy.ecs_execution_logging_policy_slave_jenkins.arn
}


## ecs_task_role for the task to interact with AWS services and permissions in general
resource "aws_iam_role" "ecs_task_role_slave_jenkins" {
  name = "ecs_task_role_slave_jenkins"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}



# Add CloudWatch logging permissions to Task Role
resource "aws_iam_policy" "ecs_task_logging_policy_slave_jenkins" {
  name        = "ecs_task_logging_policy_slave_jenkins"
  description = "Allows ECS tasks to write logs to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.ecs_cluster_cloudwatch.arn}:*"
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_logging_attachment_slave_jenkins" {
  name       = "ecs_task_logging_attachment_slave_jenkins"
  roles      = [aws_iam_role.ecs_task_role_slave_jenkins.name]
  policy_arn = aws_iam_policy.ecs_task_logging_policy_slave_jenkins.arn
}

# To log into fargate task
resource "aws_iam_policy" "ecs_ssm_exec" {
  name        = "ECS_SSM_Execute_Command"
  description = "Allows ECS tasks to use SSM Session Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:TerminateSession"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:session/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogStream"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ssm_exec_attach" {
  role       = aws_iam_role.ecs_task_role_slave_jenkins.name
  policy_arn = aws_iam_policy.ecs_ssm_exec.arn
}

# this is needed to run aws ecs execution-command
resource "aws_iam_policy_attachment" "ecs_execution_role_ssm_attachment" {
  name       = "ecs_execution_role_ssm_attachment"
  roles      = [aws_iam_role.ecs_task_role_slave_jenkins.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}