output "event_rule_arn" {
  description = "ARN of the CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.s3_object_created.arn
}