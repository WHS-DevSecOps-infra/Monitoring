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

# 계정 삭제 탐지
resource "aws_cloudwatch_event_rule" "delete_user" {
  name        = "detect-delete-user"
  description = "Detect deletion of IAM users"
  event_pattern = jsonencode({
    source       = ["aws.iam"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["DeleteUser"]
    }
  })
}

resource "aws_cloudwatch_event_target" "delete_user_to_sns" {
  rule      = aws_cloudwatch_event_rule.delete_user.name
  target_id = "DeleteUserSNS"
  arn       = aws_sns_topic.alerts.arn
}

# CloudTrail 로그가 꺼지거나 삭제된 경우
resource "aws_cloudwatch_event_rule" "cloudtrail_stop_logging" {
  name        = "detect-stop-cloudtrail"
  description = "Detect if CloudTrail logging is stopped"
  event_pattern = jsonencode({
    source       = ["aws.cloudtrail"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["StopLogging"]
    }
  })
}

resource "aws_cloudwatch_event_target" "cloudtrail_stop_to_sns" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_stop_logging.name
  target_id = "CloudTrailStopSNS"
  arn       = aws_sns_topic.alerts.arn
}

# MFA 비활성화 탐지
resource "aws_cloudwatch_event_rule" "mfa_deactivation" {
  name        = "detect-mfa-deactivation"
  description = "Detect deactivation of MFA for IAM users"
  event_pattern = jsonencode({
    source       = ["aws.iam"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = [
        "DeactivateMFADevice",
        "DeleteVirtualMFADevice"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "mfa_deactivation_to_sns" {
  rule      = aws_cloudwatch_event_rule.mfa_deactivation.name
  target_id = "MFADeactivationSNS"
  arn       = aws_sns_topic.alerts.arn
}

# 보안 그룹 수정 탐지
resource "aws_cloudwatch_event_rule" "sg_change" {
  name        = "detect-sg-change"
  description = "Detect inbound rule changes in security groups"
  event_pattern = jsonencode({
    source       = ["aws.ec2"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["AuthorizeSecurityGroupIngress"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sg_change_to_sns" {
  rule      = aws_cloudwatch_event_rule.sg_change.name
  target_id = "SGChangeSNS"
  arn       = aws_sns_topic.alerts.arn
}

# S3 퍼블릭 접근 허용 감지
resource "aws_cloudwatch_event_rule" "s3_public_access" {
  name        = "detect-s3-public-access"
  description = "Detect S3 bucket policy changes that may allow public access"
  event_pattern = jsonencode({
    source       = ["aws.s3"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["PutBucketPolicy"]
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_public_access_to_sns" {
  rule      = aws_cloudwatch_event_rule.s3_public_access.name
  target_id = "S3PublicAccessSNS"
  arn       = aws_sns_topic.alerts.arn
}

# EC2 인스턴스 생성 감지
resource "aws_cloudwatch_event_rule" "ec2_run_instances" {
  name        = "detect-ec2-run-instances"
  description = "Detect creation of new EC2 instances"
  event_pattern = jsonencode({
    source       = ["aws.ec2"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = ["RunInstances"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_run_instances_to_sns" {
  rule      = aws_cloudwatch_event_rule.ec2_run_instances.name
  target_id = "EC2RunInstancesSNS"
  arn       = aws_sns_topic.alerts.arn
}


