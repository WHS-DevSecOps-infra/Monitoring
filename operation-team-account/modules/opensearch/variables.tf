variable "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}
variable "vpc_endpoint_id" {
  description = "VPC Endpoint ID for OpenSearch"
  type        = string
}
