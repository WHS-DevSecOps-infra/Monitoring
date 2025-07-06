output "bucket_name" {
  value       = aws_s3_bucket.cloudtrail_logs.bucket
  description = "S3 bucket name for CloudTrail logs"
}

output "bucket_arn" {
  value       = aws_s3_bucket.cloudtrail_logs.arn
  description = "ARN of the S3 bucket"
}

output "kms_key_arn" {
  value       = aws_kms_key.cloudtrail.arn
  description = "KMS key ARN for S3 encryption"
}