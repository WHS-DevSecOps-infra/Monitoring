variable "lambda_function_name" {
  description = "Name of the Lambda function triggered by EventBridge"
  type        = string
}

variable "sns_topic_name" {
  description = "Name of the SNS topic for alerting"
  type        = string
}

variable "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook URL"
  type        = string
  sensitive   = true
}

variable "lambda_zip_path" {
  description = "Path to Lambda deployment package zip"
  type        = string
}

variable "opensearch_domain_arn" {
  type        = string
  description = "ARN of the OpenSearch domain"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN"
}

variable "kms_key_arn" {
  description = "KMS Key ARN used by Lambda"
  type        = string
}

variable "opensearch_domain_arn" {
  description = "OpenSearch domain ARN"
  type        = string
}