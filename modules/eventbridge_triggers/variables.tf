variable "bucket_name" {
  description = "Name of the S3 bucket where CloudTrail logs are stored"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name to be triggered"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger"
  type        = string
}