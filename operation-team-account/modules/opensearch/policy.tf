resource "aws_opensearch_domain_policy" "siem_policy" {
  domain_name = aws_opensearch_domain.siem.domain_name

  access_policies = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = [
            var.firehose_role_arn,
            data.aws_caller_identity.current.arn
          ]
        },
        Action   = [
          "es:ESHttpPut",
          "es:ESHttpPost"
        ],
        Resource = [
          "${aws_opensearch_domain.siem.arn}",
          "${aws_opensearch_domain.siem.arn}/*"
        ]
      }
    ]
  })
}
