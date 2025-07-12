resource "aws_cloudtrail" "org" {
  name                          = var.org_trail_name
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true

  s3_bucket_name = var.cloudtrail_bucket_name
  kms_key_id     = var.cloudtrail_kms_key_arn

  tags = {
    Name        = var.org_trail_name
    Environment = "prod"
    Owner       = "security-team"
  }
}