output "cloudwatch_logs_group_arn" {
  description = "ARN of the CloudWatch Logs group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail_log.arn
}

output "cloudtrail_to_cwlogs_role_arn" {
  description = "ARN of the IAM Role for CloudTrail to push to CloudWatch Logs"
  value       = aws_iam_role.cloudtrail_to_cwlogs.arn
}