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

data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket         = "cloudfence-operation-state"
    key            = "runtime-verification/lambda.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "s3-operation-lock"
  }
}

resource "aws_cloudwatch_event_rule" "inspector_event_rule" {
  name        = "inspector-event-rule"
  description = "Event rule for AWS Inspector findings"

  event_pattern = jsonencode({
    source      = ["aws.inspector2"],
    detail-type = ["Inspector2 Finding"],
    detail = {
      finding = {
        severity = ["HIGH", "CRITICAL"],
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "inspector_event_target" {
  rule = aws_cloudwatch_event_rule.inspector_event_rule.name
  arn  = data.terraform_remote_state.lambda.outputs.lambda_function_arn
}

resource "aws_lambda_permission" "inspector_event_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda.outputs.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.inspector_event_rule.arn
}