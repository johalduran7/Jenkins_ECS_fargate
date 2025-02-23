


# using the same function as the other module. It doesn't really matter
resource "aws_lambda_function" "lambda_jenkins" {
  function_name    = "lambda_jenkins"
  handler          = "lambda_function.lambda_handler" # Python handler
  runtime          = "python3.9"                      # Specify the Python runtime version
  role             = aws_iam_role.lambda_role_jenkins.arn
  timeout          = 10
  source_code_hash = filebase64sha256("modules/lambda/lambda_function.zip")

  # Specify the S3 bucket and object if you upload the ZIP file to S3, or use the `filename` attribute for local deployment
  filename = "modules/lambda/lambda_function.zip" # Path to your ZIP file
}
# cd modules/lambda/ 
# zip lambda_function.zip lambda_function.py

output "lambda_jenkins_arn" {
  value = aws_lambda_function.lambda_jenkins.arn
}

output "lambda_jenkins_name" {
  value = aws_lambda_function.lambda_jenkins.function_name
}
