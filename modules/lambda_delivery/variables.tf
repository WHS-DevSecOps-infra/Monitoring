variable "aws_region" { type = string }
variable "bucket_name" { type = string }
variable "domain_name" { type = string }
variable "function_name" { type = string }
variable "handler" { type = string }
variable "runtime" { type = string }
variable "zip_file_path" { type = string }
variable "opensearch_endpoint" { type = string }
variable "kms_alias_name" {
  description = "KMS key alias for CloudTrail logs"
  type        = string
}