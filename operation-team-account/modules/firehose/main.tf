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
    Version = "2012-10-17"
    Statement = [
      # 1) OpenSearch 접근 권한: 도메인 자체와 색인 아래 객체만 허용
      {
        Effect   = "Allow"
        Action   = [
          "es:DescribeElasticsearchDomain",
          "es:DescribeElasticsearchDomains", # Note: 이 액션은 리소스 지정이 불가능하여 "*" 사용 필요
          "es:DescribeElasticsearchDomainConfig",
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet",
        ]
        Resource = [
          var.opensearch_domain_arn,
          "${var.opensearch_domain_arn}/*",
        ]
      },

      # 2) S3 버킷 접근 권한: 버킷 메타데이터 조회와 객체 Put만 해당 버킷으로 제한
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",          # 버킷 목록 조회(버킷 이름에 한정)
          "s3:GetBucketLocation",   # 리전 조회
        ]
        Resource = var.s3_bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",           # 객체 업로드
        ]
        Resource = "${var.s3_bucket_arn}/*"
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
      compression_format = "GZIP"
      prefix             = "backup/"
    }
  }
}
# S3 버킷에 Lifecycle 정책 붙이기
resource "aws_s3_bucket_lifecycle_configuration" "firehose_backup" {
  bucket = aws_s3_bucket.firehose_backup.id

  rule {
    id     = "ExpireBackup"
    status = "Enabled"

    filter { prefix = "backup/" }

    expiration { days = 7 }     # 7일 지난 백업은 자동 삭제
  }
}