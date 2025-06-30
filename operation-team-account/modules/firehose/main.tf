variable "s3_bucket_arn"          { type = string }
variable "opensearch_domain_arn" { type = string }

resource "aws_iam_role" "firehose_role" {
  name = "firehose_delivery_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "firehose.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose-opensearch-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
  Version = "2012-10-17",
  Statement = [
    {
      Effect = "Allow",
      Action = [
        "es:DescribeElasticsearchDomain",
        "es:DescribeElasticsearchDomains",
        "es:DescribeElasticsearchDomainConfig",
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpGet"
      ],
      Resource = var.opensearch_domain_arn
    },
    {
      Effect = "Allow",
      Action = [
        "s3:PutObject"
      ],
      Resource = "${var.s3_bucket_arn}/AWSLogs/*"
    },
    {
      Effect = "Allow",
      Action = [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ],
      Resource = var.s3_bucket_arn
    }
  ]
})
}

resource "aws_kinesis_firehose_delivery_stream" "to_opensearch" {
  name        = "firehose-to-opensearch"
  destination = "elasticsearch"

  elasticsearch_configuration {
    domain_arn         = var.opensearch_domain_arn
    role_arn           = aws_iam_role.firehose_role.arn
    index_name         = "cloudtrail-logs"
    buffering_size     = 5
    buffering_interval = 60
    retry_duration     = 300
    s3_backup_mode     = "FailedDocumentsOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = var.s3_bucket_arn
      buffering_interval = 300
      buffering_size     = 5
      compression_format = "GZIP"
      error_output_prefix = "errors/"
    }
  }

  tags = {
    Name        = "firehose-opensearch"
    Environment = "dev"
    Owner       = "monitoring-team"
  }
}

output "firehose_role_arn" {
  value = aws_iam_role.firehose_role.arn
}
