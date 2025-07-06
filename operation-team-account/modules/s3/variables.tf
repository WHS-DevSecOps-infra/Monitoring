variable "bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail in the management account"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "management_account_id" {
  description = "AWS Account ID of the Management account (CloudTrail producer)"
  type        = string
}