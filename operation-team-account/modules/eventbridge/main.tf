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

# 루트 계정 로그인 실패 탐지
resource "aws_cloudwatch_event_rule" "detect_root_fail" {
  name        = "detect-root-login-failure"
  description = "Detect failed root console login"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName    = ["ConsoleLogin"]
      errorCode    = ["FailedAuthentication"]
      userIdentity = { type = ["Root"] }
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_root_fail" {
  rule      = aws_cloudwatch_event_rule.detect_root_fail.name
  target_id = "root-fail"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_root_fail" {
  statement_id  = "AllowDetectRootFail"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_root_fail.arn
}

# 권한 변경 액션 탐지
resource "aws_cloudwatch_event_rule" "detect_permission_change" {
  name        = "detect-iam-permission-change"
  description = "Detect changes to IAM policies"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "AttachUserPolicy", "DetachUserPolicy",
        "PutUserPolicy", "DeleteUserPolicy",
        "CreatePolicy", "DeletePolicy"
      ]
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_permission_change" {
  rule      = aws_cloudwatch_event_rule.detect_permission_change.name
  target_id = "permission-change"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_permission_change" {
  statement_id  = "AllowDetectPermissionChange"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_permission_change.arn
}

# IAM 사용자/역할 삭제 탐지
resource "aws_cloudwatch_event_rule" "detect_iam_delete" {
  name        = "detect-iam-deletion"
  description = "Detect deletion of IAM users, roles, or login profiles"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["DeleteUser", "DeleteRole", "DeleteLoginProfile"]
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_iam_delete" {
  rule      = aws_cloudwatch_event_rule.detect_iam_delete.name
  target_id = "iam-deletion"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_iam_delete" {
  statement_id  = "AllowDetectIamDelete"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_iam_delete.arn
}

# CloudTrail 로그 중지/삭제 탐지
resource "aws_cloudwatch_event_rule" "detect_cloudtrail_disable" {
  name        = "detect-cloudtrail-disable"
  description = "Detect when CloudTrail is stopped or deleted"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["StopLogging", "DeleteTrail"]
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_cloudtrail_disable" {
  rule      = aws_cloudwatch_event_rule.detect_cloudtrail_disable.name
  target_id = "cloudtrail-disable"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_cloudtrail_disable" {
  statement_id  = "AllowDetectCloudtrailDisable"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_cloudtrail_disable.arn
}

# MFA 디바이스 비활성화 탐지
resource "aws_cloudwatch_event_rule" "detect_mfa_deactivate" {
  name        = "detect-mfa-deactivation"
  description = "Detect MFA deactivation or deletion"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["DeactivateMFADevice", "DeleteVirtualMFADevice"]
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_mfa_deactivate" {
  rule      = aws_cloudwatch_event_rule.detect_mfa_deactivate.name
  target_id = "mfa-deactivate"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_mfa_deactivate" {
  statement_id  = "AllowDetectMfaDeactivate"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_mfa_deactivate.arn
}

# 보안 그룹 규칙 변경 탐지
resource "aws_cloudwatch_event_rule" "detect_sg_change" {
  name        = "detect-security-group-change"
  description = "Detect changes to Security Group ingress/egress rules"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "AuthorizeSecurityGroupIngress", "RevokeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress", "RevokeSecurityGroupEgress"
      ]
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_sg_change" {
  rule      = aws_cloudwatch_event_rule.detect_sg_change.name
  target_id = "sg-change"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_sg_change" {
  statement_id  = "AllowDetectSgChange"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_sg_change.arn
}

# S3 퍼블릭 접근 허용 탐지
resource "aws_cloudwatch_event_rule" "detect_s3_public" {
  name        = "detect-s3-public-access"
  description = "Detect when S3 bucket ACL or policy makes it public"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["PutBucketAcl", "PutBucketPolicy", "PutPublicAccessBlock"]
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_s3_public" {
  rule      = aws_cloudwatch_event_rule.detect_s3_public.name
  target_id = "s3-public"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_s3_public" {
  statement_id  = "AllowDetectS3Public"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_s3_public.arn
}

# EC2 인스턴스 생성 탐지
resource "aws_cloudwatch_event_rule" "detect_ec2_launch" {
  name        = "detect-ec2-instance-launch"
  description = "Detect when EC2 instances are launched"
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["RunInstances"]
    }
  })
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "detect_ec2_launch" {
  rule      = aws_cloudwatch_event_rule.detect_ec2_launch.name
  target_id = "ec2-launch"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_detect_ec2_launch" {
  statement_id  = "AllowDetectEc2Launch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.detect_ec2_launch.arn
}