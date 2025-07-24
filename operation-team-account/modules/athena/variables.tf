variable "athena_log_bucket_name" {
  description = "S3 bucket where Athena logs are stored"
  type        = string
  default = "whs-athena"
}

variable "log_prefix" {
  description = "Prefix path in S3 for Athena logs"
  type        = string
  default     = "query-results/"
}

# athena 쿼리 결과가 저장된 로그 30일 후에 자동으로 삭제됨.
variable "log_retention_days" {
  description = "Number of days to retain Athena logs"
  type        = number
  default     = 30
}

# variable "cloudwatch_log_group" {
#   description = "Name of the CloudWatch log group for Athena"
#   type        = string
# }

