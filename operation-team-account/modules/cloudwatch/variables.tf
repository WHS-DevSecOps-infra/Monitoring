variable "subscription_filter_name" {
  description = "CloudWatch Logs Subscription Filter 이름"
  type        = string
}

variable "log_group_name" {
  description = "대상 CloudWatch 로그 그룹 이름"
  type        = string
}

variable "firehose_arn" {
  description = "로그를 전송할 Kinesis Firehose ARN"
  type        = string
}

variable "role_arn" {
  description = "CloudWatch Logs → Firehose 연결용 IAM Role ARN"
  type        = string
}
