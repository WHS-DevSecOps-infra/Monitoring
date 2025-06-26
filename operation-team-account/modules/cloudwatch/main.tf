resource "aws_cloudwatch_log_group" "target" {
  name              = var.log_group_name
  retention_in_days = 14
}

resource "aws_cloudwatch_log_subscription_filter" "logs_to_firehose" {
  name            = var.subscription_filter_name
  log_group_name  = var.log_group_name
  filter_pattern  = "{ $.level = \"ERROR\" }"
  destination_arn = var.firehose_arn
  role_arn        = var.role_arn
}
