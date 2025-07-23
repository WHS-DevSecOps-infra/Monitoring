resource "aws_iam_role" "opensearch_setup_role" {
  name = "opensearch-setup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "opensearch_initializer_custom" {
  name = "opensearch-initializer-minimal"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "MinimalOpenSearchAccess",
        Effect = "Allow",
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPost",
          "es:ESHttpPut"
        ],
        Resource = "${var.opensearch_domain_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_initializer_minimal" {
  role       = aws_iam_role.opensearch_setup_role.name
  policy_arn = aws_iam_policy.opensearch_initializer_custom.arn
}

resource "aws_iam_policy_attachment" "lambda_vpc_access" {
  name       = "attach-vpc-access"
  roles      = [aws_iam_role.opensearch_setup_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_lambda_function" "initializer" {
  function_name = "opensearch-initializer"
  role          = aws_iam_role.opensearch_setup_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  timeout       = 30

  filename         = "${path.module}/lambda_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_package.zip")

    environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_url
      SLACK_WEBHOOK_URL   = var.slack_webhook_url
      EVENT_NAMES         = jsonencode(var.detect_event_names)
    }
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name = "opensearch-initializer-logging"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_logging" {
  role       = aws_iam_role.opensearch_setup_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}