data "aws_caller_identity" "current" {}

# KMS 키 (CloudTrail 로그 암호화용)
resource "aws_kms_key" "cloudtrail" {
  description         = "KMS key for encrypting CloudTrail logs"
  enable_key_rotation = true

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRootAccountFullAccess"
        Effect    = "Allow"
        Principal = {
          AWS = [
           "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", # Operation root
           "arn:aws:iam::${var.management_account_id}:root",                    # Management root
         ]
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # 조직 전체 Organization Trail 전용: CloudTrail 서비스가 이 키를 사용할 수 있도록 허용
      {
        Sid       = "AllowOrgCloudTrailUse"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.organization_id,
            "kms:ViaService"     = "cloudtrail.${var.aws_region}.amazonaws.com"
          }
        }
      },
      # S3 서비스에서 이 키를 사용해 암호화할 수 있도록 허용
      {
        Sid       = "AllowS3UseOfTheKey"
        Effect    = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceArn"     = "arn:aws:s3:::${var.bucket_name}",
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# S3 버킷 생성
resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name
}

# 버전 관리 설정
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-KMS 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail.arn
    }
  }
}

# 공개 접근 차단
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail에서 로그를 S3에 쓸 수 있도록 정책 설정
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      # GetBucketAcl 권한
      {
        Sid       = "AllowCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      # CloudTrail에서 PutObject 허용 (조직 전체 Organization Trail)
      {
        Sid       = "AllowCloudTrailWriteFromOrg"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms",
            "s3:x-amz-acl"                    = "bucket-owner-full-control",
            "aws:PrincipalOrgID"              = var.organization_id
          }
        }
      }
    ]
  })
}

# 라이프사이클 정책 (30일 후 만료)
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs-after-30-days"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}