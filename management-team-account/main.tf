terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "cloudfence-management-state"
    key            = "cloudtrail/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "tfstate-management-lock"
  }
}

provider "aws" {
  region  = var.aws_region
}

data "terraform_remote_state" "operation" {
  backend = "s3"
  config = {
    bucket  = "cloudfence-operation-state"
    key     = "monitoring/terraform.tfstate"
    region  = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}

module "cloudtrail" {
  source                 = "../modules/cloudtrail_org"
  org_trail_name         = var.org_trail_name
  cloudtrail_bucket_name = data.terraform_remote_state.operation.outputs.bucket_name
  cloudtrail_kms_key_arn = data.terraform_remote_state.operation.outputs.kms_key_arn
}