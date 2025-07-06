output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.eventbridge_processor.arn
}

output "lambda_function_role_arn" {
  description = "IAM Role ARN of the Lambda function"
  value       = aws_iam_role.lambda_exec.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.alerts.arn
}