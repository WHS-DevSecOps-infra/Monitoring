terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

provider "aws" {
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "operation"
  region = "ap-northeast-2"
}

data "aws_caller_identity" "operation" {
  provider = aws.operation
}

resource "aws_inspector2_delegated_admin_account" "this" {
  account_id = data.aws_caller_identity.operation.account_id
}