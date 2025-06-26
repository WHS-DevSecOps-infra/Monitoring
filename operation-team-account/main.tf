terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "<YOUR-SECURE-TFSTATE-BUCKET>"
    key     = "devsecops/monitoring/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
     dynamodb_table = "tf-lock"
  }
}

provider "aws" {
  region = var.aws_region
  profile = "devsecops-sso"
}

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
