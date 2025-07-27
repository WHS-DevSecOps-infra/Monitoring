# management account
resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "cloudtrail-s3-event-rule"
  description = "Trigger Lambda on CloudTrail S3 delivery objects"

  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail = {
      eventName = ["PutObject"]
      requestParameters = {
        bucketName = [var.bucket_name]
        key        = [{ prefix = "AWSLogs/" }]
      }
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "lambda-target"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}