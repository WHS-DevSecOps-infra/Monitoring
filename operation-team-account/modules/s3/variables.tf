variable "bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail (for tag, optional)"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "management_account_id" {
  description = "Management account AWS ID"
  type        = string
}

variable "organization_id" {
  description = "Organization ID (for cross-account policy, optional)"
  type        = string
}