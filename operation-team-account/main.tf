data "aws_caller_identity" "current" {}

terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "cloudfence-operation-s3"
    key     = "monitoring/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "tfstate-operation-lock"
    profile        = "whs-sso-operation"
  }
}

provider "aws" {
  region = var.aws_region
  profile = "whs-sso-operation"
}

provider "aws" {
  alias  = "management"
  region = var.aws_region
  profile = "whs-sso-management"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.cloudtrail_bucket_name
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

module "cloudwatch" {
  source                     = "./modules/cloudwatch"
  aws_region                 = var.aws_region
  firehose_stream_name       = module.firehose.firehose_stream_name
  firehose_role_arn          = module.firehose.firehose_role_arn
  firehose_arn               = module.firehose.firehose_arn
  cloudwatch_log_group_name  = "/aws/cloudtrail/logs"
  management_account_id      = var.management_account_id
  cloudtrail_logs_role_arn   = module.cloudwatch.cloudtrail_to_cwlogs_role_arn

   providers = {
    aws = aws
    aws.management = aws.management
  }
}
