data "terraform_remote_state" "operation" {
  backend = "s3"
  config = {
    bucket  = "cloudfence-operation-s3"
    key     = "monitoring/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "whs-sso-operation"
  }
}

terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "cloudfence-management-s3"
    key            = "cloudtrail/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "tfstate-management-lock"
    profile        = "whs-sso-management"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "whs-sso-management"
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "org" {
  name                          = var.org_trail_name
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true

  s3_bucket_name                = var.destination_s3_bucket_name
  kms_key_id                    = var.s3_kms_key_arn
  cloud_watch_logs_group_arn  = data.terraform_remote_state.operation.outputs.cloudwatch_logs_group_arn
  cloud_watch_logs_role_arn   = data.terraform_remote_state.operation.outputs.cloudtrail_to_cwlogs_role_arn


  tags = {
    Name        = var.org_trail_name
    Environment = "prod"
    Owner       = "security-team"
  }
}