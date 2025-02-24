resource "aws_cloudwatch_event_rule" "instance_shutdown" {
  name        = "instance-shutdown"
  description = "Trigger Lambda when EC2 instance is about to be shut down"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["shutting-down", "terminated"]
    }
  })
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
  source_arn    = aws_cloudwatch_event_rule.instance_shutdown.arn
}

# EventBridge config for lambda funciton to delete the volume once the snapshot is taken
resource "aws_cloudwatch_event_rule" "delete_volume" {
  name        = "delete_volume"
  description = "Trigger Lambda when the snapshot is taken"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EBS Snapshot Notification"]
    detail = {
      event  = ["createSnapshot"]
      result = ["succeeded"]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_lambda_delete_volume" {
  rule      = aws_cloudwatch_event_rule.delete_volume.name
  target_id = "TriggerLambdaDeleteVolume"
  arn       = var.lambda_jenkins_delete_volume_arn
}

resource "aws_lambda_permission" "eventbridge_permission_delete_volume" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_jenkins_delete_volume_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.delete_volume.arn
}

