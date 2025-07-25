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

resource "aws_inspector2_delegated_admin_account" "this" {
  account_id = var.operation_account_id
}