variable "s3_bucket_name" { type = string }
variable "kms_key_arn"    { type = string }

resource "aws_cloudtrail" "org" {
  name                          = "org-cloudtrail"
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true
  s3_bucket_name                = var.s3_bucket_name
  kms_key_id                    = var.kms_key_arn

  tags = {
    Name        = "org-cloudtrail"
    Environment = "dev"
    Owner       = "monitoring-team"
  }
}

output "status" {
  description = "CloudTrail logging enabled"
  value       = aws_cloudtrail.org.is_logging
}
