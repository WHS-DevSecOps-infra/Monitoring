# Root Module: main.tf
terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "<YOUR-TFSTATE-BUCKET>"
    key    = "devsecops/monitoring/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Root module invoking sub-modules
module "s3" {
  source      = "./modules/s3"
  bucket_name = var.cloudtrail_bucket_name
}

module "cloudtrail" {
  source          = "./modules/cloudtrail"
  s3_bucket_name  = module.s3.bucket_name
  kms_key_arn     = module.s3.kms_key_arn
}

module "firehose" {
  source                = "./modules/firehose"
  s3_bucket_arn         = module.s3.bucket_arn
  opensearch_domain_arn = module.opensearch.domain_arn
}

module "opensearch" {
  source                 = "./modules/opensearch"
  domain_name            = var.opensearch_domain_name
  engine_version         = var.opensearch_engine_version
  cluster_instance_type  = var.opensearch_instance_type
  cluster_instance_count = var.opensearch_instance_count
  ebs_volume_size        = var.opensearch_ebs_size
  kms_key_arn            = module.s3.kms_key_arn
  firehose_role_arn      = module.firehose.firehose_role_arn
}

module "detection" {
  source          = "./modules/detection"
  sns_topic_name  = var.alerts_sns_topic
}

# Variables: variables.tf
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
  default     = "devsecops-cloudtrail-logs"
}

variable "opensearch_domain_name" {
  description = "OpenSearch domain name"
  type        = string
  default     = "siem-domain"
}

variable "opensearch_engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.9"
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

variable "alerts_sns_topic" {
  description = "SNS topic name for security alerts"
  type        = string
  default     = "security-alerts"
}

# Outputs: outputs.tf
output "opensearch_endpoint" {
  description = "Endpoint URL of the OpenSearch domain"
  value       = module.opensearch.endpoint
}

output "cloudtrail_status" {
  description = "CloudTrail logging status"
  value       = module.cloudtrail.status
}
