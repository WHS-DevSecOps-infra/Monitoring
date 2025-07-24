data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # CloudWatch 로그 권한
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*"
      },
      # OpenSearch POST 권한
      {
        Effect = "Allow",
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet"
        ],
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*"
      }
    ]
  })
}

resource "aws_lambda_function" "alerting_setup" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = var.runtime
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
  filename         = "${path.module}/${var.zip_file_path}"
  source_code_hash = filebase64sha256("${path.module}/${var.zip_file_path}")

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
      SLACK_WEBHOOK_URL   = var.slack_webhook_url
    }
  }
}

output "lambda_function_name" {
  value = aws_lambda_function.alerting_setup.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.alerting_setup.arn
}