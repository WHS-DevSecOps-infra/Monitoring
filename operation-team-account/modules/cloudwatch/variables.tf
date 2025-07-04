variable "aws_region" {
  description = "AWS region (for IAM trust policy)"
  type        = string
}

variable "management_account_id" {
  description = "AWS account ID of the management account"
  type        = string
}

variable "cloudtrail_logs_role_arn" {
  description = "IAM Role ARN for CloudTrail to push logs to CloudWatch"
  type        = string
}

variable "firehose_role_arn" {
  description = "IAM role ARN for CloudWatch Logs to publish to Firehose"
  type        = string
}

variable "firehose_arn" {
  description = "ARN of the Kinesis Firehose stream"
  type        = string
}

