data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.bucket_name}/AWSLogs/*"
      },
      {
        Effect   = "Allow"
        Action   = ["es:ESHttpPost", "es:ESHttpPut", "es:ESHttpGet"]
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*"
      }
    ]
  })
}

data "aws_kms_alias" "cloudtrail_logs" {
  name = var.kms_alias_name
}

resource "aws_iam_policy" "kms_decrypt" {
  name = "AllowKMSDecryptForS3Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect   = "Allow",
        Action   = ["kms:Decrypt"],
        Resource = data.aws_kms_alias.cloudtrail_logs.target_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kms_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.kms_decrypt.arn
}
resource "aws_lambda_function" "delivery" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = var.runtime
  role             = aws_iam_role.lambda_exec.arn
  filename         = "${path.module}/${var.zip_file_path}"
  source_code_hash = filebase64sha256("${path.module}/${var.zip_file_path}")

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
    }
  }
}

output "lambda_function_name" { value = aws_lambda_function.delivery.function_name }
output "lambda_function_arn" { value = aws_lambda_function.delivery.arn }