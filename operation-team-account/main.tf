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
    bucket         = "cloudfence-operation-s3"
    key            = "monitoring/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "tfstate-operation-lock"
    profile        = "whs-sso-operation"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "whs-sso-operation"
}

provider "aws" {
  alias   = "management"
  region  = var.aws_region
  profile = "whs-sso-management"
}

module "s3" {
  source           = "./modules/s3"
  bucket_name      = var.cloudtrail_bucket_name
  cloudtrail_name  = var.org_trail_name
  aws_region = var.aws_region
}

module "detection" {
  source              = "./modules/detection"
  sns_topic_name      = var.alerts_sns_topic
  lambda_function_name = "eventbridge-processor"
  opensearch_domain_endpoint = module.opensearch.endpoint
  slack_webhook_url   = var.slack_webhook_url
  lambda_zip_path     = "./lambda/lambda_package.zip"
  kms_key_arn            = module.s3.kms_key_arn
  opensearch_domain_arn = module.opensearch.domain_arn
  aws_region = var.aws_region
}

output "opensearch_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.opensearch.id
  description = "The ID of the VPC endpoint for OpenSearch"
}


module "opensearch" {
  source                 = "./modules/opensearch"
  domain_name            = var.opensearch_domain_name
  engine_version         = var.opensearch_engine_version
  cluster_instance_type  = var.opensearch_instance_type
  cluster_instance_count = var.opensearch_instance_count
  ebs_volume_size        = var.opensearch_ebs_size
  kms_key_arn            = module.s3.kms_key_arn
  lambda_role_arn        = module.detection.lambda_function_role_arn
  vpc_endpoint_id = module.network.opensearch_vpc_endpoint_id
}

module "network" {
  source     = "./modules/network"
  aws_region = var.aws_region
}

