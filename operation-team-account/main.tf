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

# 2) S3 모듈: CloudTrail 로그 버킷 + KMS
module "s3" {
  source                = "../modules/s3_cloudtrail_logs"
  bucket_name           = var.cloudtrail_bucket_name
  aws_region            = var.aws_region
  kms_alias_name        = var.kms_alias_name
  management_account_id = data.aws_caller_identity.management.account_id
}

# 3) OpenSearch 모듈: 도메인 생성 + 접근 정책
module "opensearch" {
  source                   = "../modules/opensearch"
  domain_name              = var.opensearch_domain_name
  engine_version           = var.opensearch_engine_version
  cluster_instance_type    = var.opensearch_instance_type
  cluster_instance_count   = var.opensearch_instance_count
  ebs_volume_size          = var.opensearch_ebs_size
  kms_key_arn              = module.s3.kms_key_arn
  lambda_role_arn          = module.lambda.lambda_function_role_arn
  allowed_source_ips       = var.allowed_source_ips
}

# 4) Lambda 모듈: 로그 파싱 → OpenSearch + Slack 전송
module "lambda" {
  source                    = "../modules/lambda_log_processor"
  lambda_function_name      = "cloudtrail-log-processor"
  lambda_zip_path           = "../modules/lambda_log_processor/lambda_package.zip"
  opensearch_domain_arn     = module.opensearch.domain_arn
  opensearch_endpoint       = module.opensearch.endpoint
  kms_key_arn               = module.s3.kms_key_arn
  bucket_arn                = module.s3.bucket_arn
  lambda_subnet_ids         = [module.network.private_subnet_id]
  lambda_security_group_ids = [module.network.lambda_sg_id]
}

# 5) EventBridge 모듈: S3 PutObject → Lambda 트리거
module "eventbridge" {
  source               = "../modules/eventbridge_triggers"
  bucket_name          = module.s3.bucket_name
  lambda_function_name = module.lambda.lambda_function_name
  lambda_function_arn  = module.lambda.lambda_function_arn
}

# 6) network 모듈 호출
module "network" {
  source     = "../modules/network_vpc"
  aws_region = var.aws_region
}

module "opensearch_initializer" {
  source             = "../modules/opensearch_initializer"
  opensearch_url     = "https://${module.opensearch.endpoint}"
  slack_webhook_url  = var.slack_webhook_url
  opensearch_domain_arn = module.opensearch.domain_arn
}