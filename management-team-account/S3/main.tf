terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# S3 버킷 생성
resource "aws_s3_bucket" "state_org" {
  bucket = "cloudfence-management-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "management"
  }
}

# 버킷 버전 관리
resource "aws_s3_bucket_versioning" "state_org_versioning" {
  bucket = aws_s3_bucket.state_org.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 버킷 소유권 제어
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.state_org.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# 퍼블릭 접근 차단
resource "aws_s3_bucket_public_access_block" "state_org_block" {
  bucket                  = aws_s3_bucket.state_org.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


data "aws_caller_identity" "current" {}


# S3 암호화를 위한 KMS 키
resource "aws_kms_key" "s3_key" {
  description         = "KMS key for S3 encryption"
  enable_key_rotation = true

  # KMS 키 정책 추가
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # 현재 계정에게 모든 KMS 작업 권한 부여
      {
        Sid    = "AllowRootAccountFullAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },

      # S3 서비스에게 암복호화 권한 부여
      {
        Sid    = "AllowS3ServicePrincipal"
        Effect = "Allow"
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
            "aws:SourceArn"     = "arn:aws:s3:::cloudfence-management-state",
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# S3 버킷 서버 측 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.state_org.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}
