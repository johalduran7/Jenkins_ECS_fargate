
resource "aws_iam_role" "lambda_role_jenkins" {
  name = "lambda_role_jenkins"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_role_jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"

}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_AWSLambdaBasic_forCW" {
  role       = aws_iam_role.lambda_role_jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Permmmissions for EBS:
resource "aws_iam_policy" "snapshot_policy" {
  name        = "snapshot_policy"
  description = "Allow Lambda to create snapshots"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateSnapshot",
        "ec2:DescribeVolumes",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DeleteSnapshot",
        "ec2:TagResource",
        "ec2:CreateTags"

      ]
      Resource = "*"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_snapshot_attach" {
  role       = aws_iam_role.lambda_role_jenkins.name
  policy_arn = aws_iam_policy.snapshot_policy.arn
}

resource "aws_iam_policy" "ssm_update_parameter_policy" {
  name        = "SSMUpdateParameterPolicy"
  description = "Policy to allow updating Parameter Store values"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_update_policy" {
  policy_arn = aws_iam_policy.ssm_update_parameter_policy.arn
  role       = aws_iam_role.lambda_role_jenkins.name
}