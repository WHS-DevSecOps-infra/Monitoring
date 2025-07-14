variable "domain_name" {
  description = "OpenSearch domain name (without prefix)"
  type        = string
  default     = "siem-whs-domain"
}

variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.11"
}

variable "cluster_instance_type" {
  description = "Instance type for OpenSearch nodes"
  type        = string
  default     = "t3.small.search"
}

variable "cluster_instance_count" {
  description = "Number of OpenSearch instances"
  type        = number
  default     = 1
}

variable "ebs_volume_size" {
  description = "EBS volume size (GiB) for each OpenSearch node"
  type        = number
  default     = 10
}

variable "kms_key_arn" {
  description = "KMS key ARN to encrypt OpenSearch data at rest"
  type        = string
  default     = "arn:aws:kms:ap-northeast-2:123456789012:key/your-kms-key-id"
}

variable "lambda_role_arn" {
  description = "IAM Role ARN that Lambda will assume for indexing into OpenSearch"
  type        = string
  default     = "arn:aws:iam::123456789012:role/opensearch-lambda-role"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the OpenSearch domain VPC configuration"
  type        = list(string)
  default     = ["subnet-0123456789abcdef0", "subnet-0abcdef1234567890"]
}

variable "security_group_ids" {
  description = "List of security group IDs for OpenSearch"
  type        = list(string)
  default     = ["sg-0123456789abcdef0"]
}

variable "basic_auth_user" {
  description = "Basic auth user for OpenSearch Dashboards"
  type        = string
  default     = "admin"
}

variable "basic_auth_pass" {
  description = "Basic auth password for OpenSearch Dashboards"
  type        = string
  sensitive   = true
  default     = "StrongPassword123!"
}

variable "region" {
  description = "AWS region where the OpenSearch domain will be created"
  type        = string
  default     = "ap-northeast-2"
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL for notifications"
  type        = string
}
