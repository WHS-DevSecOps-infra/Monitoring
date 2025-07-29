output "lambda_function_arn" {
  description = "The ARN of the Inspector Slack notification Lambda function"
  value       = aws_lambda_function.inspector_slack_notification.arn
}

output "lambda_function_name" {
  description = "The name of the Inspector Slack notification Lambda function"
  value       = aws_lambda_function.inspector_slack_notification.function_name
}