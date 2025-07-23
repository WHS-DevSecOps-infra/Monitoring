variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "lambda_zip_path" {
  type        = string
  description = "Path to the zipped Lambda package"
}

variable "opensearch_domain_arn" {
  type        = string
  description = "ARN of the OpenSearch domain"
}

variable "opensearch_endpoint" {
  type        = string
  description = "OpenSearch endpoint URL"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key for decrypting Slack secret (if encrypted)"
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket for CloudTrail logs"
  type        = string
}

variable "lambda_subnet_ids" {
  description = "List of subnet IDs for the Lambda function to attach to the VPC"
  type        = list(string)
}

variable "lambda_security_group_ids" {
  description = "Security group IDs for the Lambda function in the VPC"
  type        = list(string)
}