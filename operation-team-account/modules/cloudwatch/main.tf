variable "firehose_stream_name" {
  type = string
}

variable "cloudwatch_log_group_name" {
  type = string
}

resource "aws_cloudwatch_log_group" "cloudtrail_log" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = 30
}

data "aws_caller_identity" "management" {
  provider = aws.management
}

resource "aws_iam_role" "cloudtrail_to_cwlogs" {
  name = "cloudtrail-to-cwlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.management.account_id}:trail/org-cloudtrail"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "cloudwatch_to_firehose_policy" {
  name = "cloudwatch-to-firehose-policy"
  role = split("/", var.firehose_role_arn)[1]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "firehose:PutRecord",
        "firehose:PutRecordBatch"
      ],
      Resource = var.firehose_arn
    }]
  })
}

#resource "aws_cloudwatch_log_subscription_filter" "to_firehose" {
#  name            = "cloudtrail-to-firehose"
#  log_group_name  = aws_cloudwatch_log_group.cloudtrail_log.name
#  filter_pattern  = ""
#  destination_arn = var.firehose_arn
#  role_arn        = var.firehose_role_arn
#}

resource "aws_iam_role_policy" "cloudtrail_to_cwlogs_policy" {
  name = "cloudtrail-to-cwlogs-policy"
  role = aws_iam_role.cloudtrail_to_cwlogs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = "${aws_cloudwatch_log_group.cloudtrail_log.arn}:*"
    }]
  })
}
