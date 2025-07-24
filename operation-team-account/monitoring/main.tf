terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "cloudfence-operation-state"
    key            = "monitoring/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "tfstate-operation-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "management"
  region = var.aws_region
}

data "aws_caller_identity" "management" {
  provider = aws.management
}

provider "aws" {
  alias  = "prod"
  region = var.aws_region
}

data "aws_caller_identity" "prod" {
  provider = aws.prod
}

data "aws_caller_identity" "current" {}

module "s3" {
  source                = "../../modules/s3_logs"
  bucket_name           = var.cloudtrail_bucket_name
  aws_region            = var.aws_region
  kms_alias_name        = var.kms_alias_name
  management_account_id = data.aws_caller_identity.management.account_id
  prod_account_id       = data.aws_caller_identity.prod.account_id
}

module "opensearch_domain" {
  source             = "../../modules/opensearch_domain"
  domain_name        = var.opensearch_domain_name
  engine_version     = var.opensearch_engine_version
  instance_type      = var.opensearch_instance_type
  instance_count     = var.opensearch_instance_count
  ebs_size           = var.opensearch_ebs_size
  allowed_source_ips = var.allowed_source_ips
  aws_region         = var.aws_region
}

module "lambda_alerting" {
  source              = "../../modules/lambda_alerting"
  aws_region          = var.aws_region
  function_name       = "opensearch-alerting-setup"
  handler             = "index.handler"
  runtime             = "nodejs18.x"
  zip_file_path       = "init-alerting.zip"
  domain_name         = var.opensearch_domain_name
  opensearch_endpoint = module.opensearch_domain.endpoint
  slack_webhook_url   = var.slack_webhook_url
}

module "lambda_delivery" {
  source              = "../../modules/lambda_delivery"
  aws_region          = var.aws_region
  domain_name         = var.opensearch_domain_name
  function_name       = "s3-to-opensearch-delivery"
  handler             = "index.handler"
  runtime             = "nodejs18.x"
  zip_file_path       = "delivery.zip"
  bucket_name         = module.s3.bucket_name
  opensearch_endpoint = module.opensearch_domain.endpoint
  kms_alias_name      = var.kms_alias_name
}

module "eventbridge" {
  source               = "../../modules/eventbridge_triggers"
  bucket_name          = module.s3.bucket_name
  lambda_function_name = module.lambda_delivery.lambda_function_name
  lambda_function_arn  = module.lambda_delivery.lambda_function_arn
}