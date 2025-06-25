resource "aws_cloudwatch_log_subscription_filter" "logs_to_firehose" {
  name            = var.subscription_filter_name
  log_group_name  = var.log_group_name
  filter_pattern  = "{ $.level = \"ERROR\" }" # ERROR 레벨만 전달
  destination_arn = var.firehose_arn
  role_arn        = var.role_arn
}

resource "aws_cloudwatch_log_group" "target" {
  name              = var.log_group_name
  retention_in_days = 14 # 14일 지나면 자동 삭제
}

resource "aws_cloudwatch_metric_filter" "error_count" {
  name           = "ErrorCount"
  log_group_name = aws_cloudwatch_log_group.target.name
  pattern        = "\"ERROR\""
  metric_transformation {
    name      = "ErrorCount"
    namespace = "MyApp/SIEM"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "HighErrorCount"
  namespace           = "MyApp/SIEM"
  metric_name         = aws_cloudwatch_metric_filter.error_count.metric_transformation[0].name
  threshold           = 100
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
