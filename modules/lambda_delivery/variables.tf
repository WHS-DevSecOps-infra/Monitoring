variable "aws_region" { type = string }
variable "bucket_name" {
  type      = string
  sensitive = true
}
variable "domain_name" {
  type      = string
  sensitive = true
}
variable "function_name" {
  type      = string
  sensitive = true
}
variable "handler" { type = string }
variable "runtime" { type = string }
variable "zip_file_path" { type = string }
variable "opensearch_endpoint" {
  type      = string
  sensitive = true
}
variable "kms_alias_name" {
  description = "KMS key alias for CloudTrail logs"
  type        = string
}