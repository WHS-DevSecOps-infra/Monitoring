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

variable "subnet_ids" {
  description = "List of subnet IDs for the OpenSearch domain VPC configuration"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the OpenSearch domain VPC configuration"
  type        = list(string)
}