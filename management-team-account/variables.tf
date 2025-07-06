variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "org_trail_name" {
  description = "Name of the organization trail"
  type        = string
  default     = "org-cloudtrail"
}

variable "destination_s3_bucket_name" {
  description = "S3 bucket name in operation account"
  type        = string
}

variable "destination_s3_bucket_arn" {
  description = "ARN of the S3 bucket in operation account"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the logs (in operation account)"
  type        = string
}

variable "sso_role_name" {
  description = "The name of the AWS SSO role to attach policy to"
  type        = string
}