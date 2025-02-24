# using the same function as the other module. It doesn't really matter
resource "aws_lambda_function" "lambda_jenkins_delete_volume" {
  function_name    = "lambda_jenkins_delete_volume"
  handler          = "lambda_function.handler" # Python handler
  runtime          = "python3.9"               # Specify the Python runtime version
  role             = aws_iam_role.lambda_role_jenkins.arn
  timeout          = 10
  source_code_hash = filebase64sha256("modules/lambda/lambda_function_delete_volume.zip")

  # Specify the S3 bucket and object if you upload the ZIP file to S3, or use the `filename` attribute for local deployment
  filename = "modules/lambda/lambda_function_delete_volume.zip" # Path to your ZIP file
  #   environment {
  #     variables = {
  #       SNAPSHOT_TAG = "jenkins_backup" # <-- Set a value here
  #     }
  #   }
}
# cd modules/lambda/ 
# zip lambda_function_delete_volume.zip lambda_function_delete_volume.py

output "lambda_jenkins_delete_volume_arn" {
  value = aws_lambda_function.lambda_jenkins_delete_volume.arn
}

output "lambda_jenkins_delete_volume_name" {
  value = aws_lambda_function.lambda_jenkins_delete_volume.function_name
}

resource "aws_cloudwatch_log_group" "lambda_log_group_delete_volume" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_jenkins_delete_volume.function_name}" # Use the log group name of your Lambda function
  retention_in_days = 1
}
