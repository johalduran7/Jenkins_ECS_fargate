# IAM Role for EC2 to Access CloudWatch
resource "aws_iam_role" "ec2_execution_role" {
  name = "${var.env}-ec2-app-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Logging Permissions
#note: "ec2:DescribeTags" this one is needed for CW Agent to run
resource "aws_iam_policy" "cloudwatch_log_policy_agent" {
  name = "${var.env}-cloudwatch-log-policy-agent"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:PutLogEvents",
          "ec2:DescribeTags",
          "cloudwatch:PutMetricData"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


# IAM Policy for SSM Access
resource "aws_iam_policy" "ssm_read_write_policy" {
  name = "${var.env}-ssm-read-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "attach_policy_cw_agent" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_log_policy_agent.arn
}

resource "aws_iam_role_policy_attachment" "attach_policy_ecr" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

resource "aws_iam_role_policy_attachment" "attach_policy_read_ssm" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = aws_iam_policy.ssm_read_write_policy.arn
}


# EC2 Instance Profile for IAM Role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.env}-ec2-instance-profile"
  role = aws_iam_role.ec2_execution_role.name
}


# IAM Policy for TAGS Access
resource "aws_iam_policy" "ec2_tags_policy" {
  name = "${var.env}-ec2_tags_policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeInstances",
            "ec2:CreateTags"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeTags",
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_policy_ec2_tags_policy" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = aws_iam_policy.ec2_tags_policy.arn
}

# Attach S3 permissions to the ECS task role
resource "aws_iam_policy" "s3_access_policy" {
  name        = "JenkinsS3Access"
  description = "Allows ECS task to access S3 backups"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        var.aws_s3_bucket_arn,
        "${var.aws_s3_bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_policy_attachment" "ec2_task_s3_access" {
  name       = "ec2-task-s3-access"
  roles      = [aws_iam_role.ec2_execution_role.name]
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# SSM permissions to access vi Session Manager:
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# EC2 to delete volumes:
resource "aws_iam_policy" "ec2_volume_policy" {
  name        = "EC2VolumePolicy"
  description = "Policy to allow EC2 instances to delete EBS volumes with the Name 'jenkins_backup'"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
        # Condition = {
        #   StringEquals = {
        #     "ec2:ResourceTag/Name" = "jenkins_volume"
        #   }
        # }
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeVolumes"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ec2_delete_volume_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_volume_policy.arn
  role       = aws_iam_role.ec2_execution_role.name
}
