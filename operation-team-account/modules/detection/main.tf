variable "sns_topic_name" { type = string }

resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 30
}

resource "aws_sns_topic" "alerts" {
  name              = var.sns_topic_name
  kms_master_key_id = aws_kms_key.sns.arn
  tags = {
    Environment = "dev"
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

# MITRE ATT&CK 기반 탐지 룰: 루트 실패 로그인
resource "aws_cloudwatch_event_rule" "root_login_failure" {
  name        = "detect-root-login-failure"
  description = "Detect failed console login attempts by root accounts"
  event_pattern = jsonencode({
    source       = ["aws.signin"],
    "detail-type" = ["AWS Console Sign In via CloudTrail"],
    detail = {
      userIdentity = { type = ["Root"] },
      responseElements = { ConsoleLogin = ["Failure"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "root_login_to_sns" {
  rule      = aws_cloudwatch_event_rule.root_login_failure.name
  target_id = "RootLoginFailureSNS"
  arn       = aws_sns_topic.alerts.arn
}

# 권한 변경 이벤트 탐지
resource "aws_cloudwatch_event_rule" "iam_policy_change" {
  name        = "detect-iam-policy-change"
  description = "Detect IAM policy modifications"
  event_pattern = jsonencode({
    source       = ["aws.iam"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = [
        "PutUserPolicy",
        "AttachUserPolicy",
        "DetachUserPolicy",
        "DeleteUserPolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "iam_change_to_sns" {
  rule      = aws_cloudwatch_event_rule.iam_policy_change.name
  target_id = "IAMPolicyChangeSNS"
  arn       = aws_sns_topic.alerts.arn
}

output "alerts_sns_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "ARN of SNS topic for security alerts"
}
