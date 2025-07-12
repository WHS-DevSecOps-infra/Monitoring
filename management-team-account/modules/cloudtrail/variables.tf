variable "org_trail_name" {
  description = "Organization CloudTrail name"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (from operation account)"
  type        = string
}

variable "cloudtrail_kms_key_arn" {
  description = "KMS key ARN for CloudTrail SSE-KMS (from operation account)"
  type        = string
}
