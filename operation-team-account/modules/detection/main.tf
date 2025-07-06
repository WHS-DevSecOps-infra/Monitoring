resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 30
}

resource "aws_sns_topic" "alerts" {
  name              = var.sns_topic_name
  kms_master_key_id = aws_kms_key.sns.arn
  tags = {
    Environment = "prod"
    Team        = "monitoring"
  }
}

resource "aws_sns_topic_policy" "alerts_policy" {
  arn = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowEventBridgePublish",
        Effect    = "Allow",
        Principal = { Service = "events.amazonaws.com" },
        Action    = "sns:Publish",
        Resource  = aws_sns_topic.alerts.arn,
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:events:*:*:rule/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "lambda_exec" {
  name = "eventbridge_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "eventbridge_lambda_policy"
  role   = aws_iam_role.lambda_exec.id
  policy = templatefile("${path.module}/iam/lambda_execution_policy.json.tpl", {
    opensearch_arn  = var.opensearch_domain_arn
    kms_key_arn     = var.kms_key_arn
    slack_secret_arn = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:slack-webhook-*"
  })
}

resource "aws_lambda_function" "eventbridge_processor" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  filename      = var.lambda_zip_path

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_domain_endpoint
      SLACK_WEBHOOK_URL   = var.slack_webhook_url
    }
  }
}

resource "aws_cloudwatch_event_rule" "mfa_deactivation" {
  name        = "detect-mfa-deactivation"
  description = "Detect deactivation of MFA for IAM users"
  event_pattern = jsonencode({
    source       = ["aws.iam"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["DeactivateMFADevice", "DeleteVirtualMFADevice"]
    }
  })
}

resource "aws_cloudwatch_event_target" "mfa_to_lambda" {
  rule      = aws_cloudwatch_event_rule.mfa_deactivation.name
  target_id = "MFAAlertLambda"
  arn       = aws_lambda_function.eventbridge_processor.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eventbridge_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mfa_deactivation.arn
}

variable "aws_region" {
  type        = string
  description = "AWS region in use"
}