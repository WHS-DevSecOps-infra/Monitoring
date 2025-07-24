output "athena_log_bucket" {
  description = "The name of the S3 bucket where Athena logs are stored"
  value       = var.athena_log_bucket_name
}

output "log_prefix" {
  description = "S3 prefix used for Athena logs"
  value       = var.log_prefix
}

output "retention_days" {
  description = "Retention period (days) for log expiration"
  value       = var.log_retention_days
}
