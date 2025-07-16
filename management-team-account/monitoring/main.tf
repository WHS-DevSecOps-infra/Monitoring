# management account
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
  region = var.aws_region
}

data "terraform_remote_state" "operation" {
  backend = "s3"
  config = {
    bucket = "cloudfence-operation-state"
    key    = "monitoring/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}

module "cloudtrail" {
<<<<<<< HEAD:management-team-account/monitoring/main.tf
  source                 = "../../modules/cloudtrail_org"
=======
  source                 = "../modules/cloudtrail_org"
<<<<<<< HEAD
>>>>>>> b154501 (refactor: 전체 폴더구조 수정(slack 알림 잘 옴)):management-team-account/main.tf
=======
>>>>>>> a230959 (refactor: 전체 폴더구조 수정(slack 알림 잘 옴)):management-team-account/main.tf
>>>>>>> b8201d3 (refactor: 전체 폴더구조 수정(slack 알림 잘 옴))
  org_trail_name         = var.org_trail_name
  cloudtrail_bucket_name = data.terraform_remote_state.operation.outputs.bucket_name
  cloudtrail_kms_key_arn = data.terraform_remote_state.operation.outputs.kms_key_arn
}