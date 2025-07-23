resource "aws_opensearch_domain_policy" "siem_policy" {
  domain_name = aws_opensearch_domain.siem.domain_name

  access_policies = jsonencode({
  Version = "2012-10-17",
  Statement = [
    {
      Effect = "Allow",
      Principal = "*",
      Action = "es:*",
      Condition = {
        IpAddress = {
          "aws:SourceIp" = var.allowed_source_ips
        }
      },
      Resource = "${aws_opensearch_domain.siem.arn}/*"
    }
  ]
})
}