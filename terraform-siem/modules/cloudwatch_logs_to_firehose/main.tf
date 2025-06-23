resource "aws_cloudwatch_log_subscription_filter" "logs_to_firehose" {
  name            = var.subscription_filter_name
  log_group_name  = var.log_group_name
  filter_pattern  = ""  # 모든 로그 전달
  destination_arn = var.firehose_arn
  role_arn        = var.role_arn
}
