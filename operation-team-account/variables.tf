variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name used by organization CloudTrail (from management account)"
  type        = string
  default     = "whs-cloudtrail-logs"
}

variable "opensearch_domain_name" {
  description = "OpenSearch domain name"
  type        = string
  default     = "whs-domain"
}

variable "opensearch_engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.11"
}

variable "opensearch_instance_type" {
  description = "OpenSearch instance type"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_instance_count" {
  description = "Number of OpenSearch instances"
  type        = number
  default     = 1
}

variable "opensearch_ebs_size" {
  description = "EBS volume size for OpenSearch"
  type        = number
  default     = 10
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL for notifications"
  type        = string
  sensitive   = true
}

variable "org_trail_name" {
  description = "Name of the organization CloudTrail trail"
  type        = string
  default     = "org-cloudtrail"
}

variable "kms_alias_name" {
  description = "KMS key alias for CloudTrail logs"
  type        = string
  default     = "alias/cloudtrail-logs"
}

variable "allowed_source_ips" {
  description = "List of IPs allowed to access the OpenSearch domain"
  type        = list(string)
  default = []
}