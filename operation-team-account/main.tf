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

data "aws_caller_identity" "current" {}

# 기본(default) VPC 자동 조회
data "aws_vpc" "default" {
  default = true
}

# 해당 VPC의 모든 서브넷 ID
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 해당 VPC의 default 보안 그룹
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

data "aws_caller_identity" "management" {
  provider = aws.management
}

# S3 모듈: CloudTrail 로그 버킷 + KMS
module "s3" {
  source                = "../modules/s3_logs"
  bucket_name           = var.cloudtrail_bucket_name
  aws_region            = var.aws_region
  kms_alias_name        = var.kms_alias_name
  management_account_id = data.aws_caller_identity.management.account_id
}

# EventBridge 모듈: S3 PutObject → Lambda 트리거
module "eventbridge" {
  source               = "../modules/eventbridge_triggers"
  bucket_name          = module.s3.bucket_name
  lambda_function_name = module.lambda.lambda_function_name
  lambda_function_arn  = module.lambda.lambda_function_arn
}