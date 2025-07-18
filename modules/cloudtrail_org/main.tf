resource "aws_cloudtrail" "org" {
  name                          = var.org_trail_name
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true

  s3_bucket_name = var.cloudtrail_bucket_name
  kms_key_id     = var.cloudtrail_kms_key_arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "arn:aws:s3:::${var.cloudtrail_bucket_name}/AWSLogs/"
      ]
    }
  }

  tags = {
    Name        = var.org_trail_name
    Environment = "prod"
    Owner       = "security-team"
  }
}