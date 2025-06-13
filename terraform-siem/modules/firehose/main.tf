resource "aws_iam_role" "firehose_role" {
  name = "siem-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose-access"
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
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "to_opensearch" {
  name        = "siem-delivery"
  destination = "opensearch"

  opensearch_configuration {
    domain_arn = var.opensearch_domain_arn
    role_arn   = aws_iam_role.firehose_role.arn
    index_name = "cw-logs"
    type_name  = "log"

    s3_backup_mode = "FailedDocumentsOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = var.s3_bucket_arn
      buffering_interval = 300
      buffering_size     = 5
      compression_format = "UNCOMPRESSED"
      prefix             = "backup/"
    }
  }
}