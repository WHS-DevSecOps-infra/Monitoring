variable "bucket_name" { type = string }

variable "aws_region" {
  description = "Region where the KMS key is created"
  type        = string
}

variable "management_account_id" {
  description = "Account ID of the management account (for S3 bucket policy)"
  type        = string
}

variable "kms_alias_name" {
  description = "KMS key alias for CloudTrail logs"
  type        = string
}

variable "prod_account_id" {
  description = "The AWS account ID for the prod account"
  type        = string
}