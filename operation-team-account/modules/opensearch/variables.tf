variable "domain_name" {
  description = "OpenSearch domain name (without prefix)"
  type        = string
}

variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
}

variable "cluster_instance_type" {
  description = "Instance type for OpenSearch nodes"
  type        = string
}

variable "cluster_instance_count" {
  description = "Number of OpenSearch instances"
  type        = number
}

variable "ebs_volume_size" {
  description = "EBS volume size (GiB) for each OpenSearch node"
  type        = number
}

variable "kms_key_arn" {
  description = "KMS key ARN to encrypt OpenSearch data at rest"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM Role ARN that Lambda will assume for indexing into OpenSearch"
  type        = string
}

variable "vpc_endpoint_id" {
  description = "VPC Endpoint ID for the OpenSearch domain"
  type        = string
}