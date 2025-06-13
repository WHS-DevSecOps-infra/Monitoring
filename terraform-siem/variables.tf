variable "log_group_name" {
  description = "CloudWatch 로그 그룹 이름"
  type        = string
}

variable "firehose_arn" {
  description = "Kinesis Firehose ARN"
  type        = string
}

variable "role_arn" {
  description = "CloudWatch → Firehose 연결용 IAM Role ARN"
  type        = string
}
