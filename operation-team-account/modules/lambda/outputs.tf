output "lambda_function_name" {
  value       = aws_lambda_function.log_processor.function_name
  description = "Name of the deployed Lambda function"
}

output "lambda_function_role_arn" {
  value       = aws_iam_role.lambda_exec.arn
  description = "IAM Role ARN for Lambda execution"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.log_processor.arn
  description = "ARN of the Lambda function"
}