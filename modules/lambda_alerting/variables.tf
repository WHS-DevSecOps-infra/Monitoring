variable "aws_region" { type = string }
variable "function_name" { type = string }
variable "handler" { type = string }
variable "runtime" { type = string }
variable "zip_file_path" { type = string }
variable "domain_name" {
  type      = string
  sensitive = true
}
variable "opensearch_endpoint" {
  type      = string
  sensitive = true
}
variable "slack_webhook_url" {
  type      = string
  sensitive = true
}