resource "aws_cloudwatch_event_rule" "instance_shutdown" {
  name        = "instance-shutdown"
  description = "Trigger Lambda when EC2 instance is about to be shut down"

  event_pattern = <<PATTERN
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"],
  "detail": {
    "state": ["shutting-down", "stopping"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.instance_shutdown.name
  target_id = "TriggerLambda"
  arn       = var.lambda_jenkins_arn
}

resource "aws_lambda_permission" "eventbridge_permission" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_jenkins_name
  principal     = "events.amazonaws.com"
  source_arn    = var.lambda_jenkins_arn
}

