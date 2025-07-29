
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

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket         = "cloudfence-operation-state"
    key            = "runtime-verification/iam.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "s3-operation-lock"
  }
}

resource "aws_lambda_function" "inspector_slack_notification" {
  function_name = "inspector_slack_notification"
  role          = data.terraform_remote_state.iam.outputs.lambda_exec_role_arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
  filename         = "lambda_function_payload.zip"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
}