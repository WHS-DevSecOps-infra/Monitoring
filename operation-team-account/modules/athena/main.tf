#포함돼야 하는 리소스들
# 1. S3에 저장된 Athena 로그를 자동으로 삭제 (비용 완화 목적)
# 2. CloudWatch Alarm으로 Athena 관련 비용 감시 (선택)
# 3. (선택) 알람 발생 시 Slack 등 알림 연동

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# Athena 로그가 저장되는 S3 버킷 (외부에서 전달됨)
resource "aws_s3_bucket_lifecycle_configuration" "athena_log_cleanup" {
  bucket = var.athena_log_bucket_name

  rule {
    id     = "athena-log-expiry"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }

    filter {
      prefix = var.log_prefix  # ex) "athena-logs/"
    }
  }
}

# CloudWatch Metric Filter (선택)
# Athena 쿼리 실패나 과도한 쿼리를 감시하려는 경우
# resource "aws_cloudwatch_log_metric_filter" "athena_query_failures" {
#   log_group_name = var.cloudwatch_log_group
#   name           = "AthenaQueryFailures"
#   pattern        = "{ $.state = \"FAILED\" }"

#   metric_transformation {
#     name      = "AthenaQueryFailuresCount"
#     namespace = "AthenaMonitoring"
#     value     = "1"
#   }
# }


