variable "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

resource "aws_opensearch_domain_policy" "siem_policy" {
  domain_name = aws_opensearch_domain.siem.domain_name

  access_policies = jsonencode({
  Version = "2012-10-17",
  Statement = [
    {
      Effect = "Allow",
      Principal = {
        AWS = var.lambda_role_arn
      },
      Action = [
        "es:ESHttpPut",
        "es:ESHttpPost",
        "es:ESHttpGet"
      ],
      Resource = [
        "${aws_opensearch_domain.siem.arn}/security-events-*"
      ],
      Condition = {
        StringEquals = {
          "aws:SourceVpce" = var.vpc_endpoint_id
        }
      }
    }
  ]
})
}