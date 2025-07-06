data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cloudtrail" {
  description         = "KMS key for encrypting CloudTrail logs"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # 운영 계정 루트에게 전체 권한
      {
        Sid       = "AllowRootAccountFullAccess"
        Effect    = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", # Operation root
            "arn:aws:iam::${var.management_account_id}:root"                    # Management root
          ]
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # CloudTrail 서비스에서 KMS 키 사용 허용 (management account)
      {
        Sid    = "AllowCloudTrailFromMgmtToUseKMS"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:DescribeKey",
          "kms:ListKeys",
          "kms:Encrypt",
          "kms:ListAliases"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount": "${var.management_account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/cloudtrail-logs"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = var.bucket_name
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = var.bucket_name
    Environment = "prod"
    Owner       = "security-team"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
  Version: "2012-10-17",
  Statement = [
    {
      Sid = "AWSCloudTrailWrite",
      Effect = "Allow",
      Principal = { "Service": "cloudtrail.amazonaws.com" },
      Action = "s3:PutObject",
      Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${var.organization_id}/*",
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
    },
    {
      Sid = "AWSCloudTrailAclCheck",
      Effect = "Allow",
      Principal = { "Service": "cloudtrail.amazonaws.com" },
      Action = "s3:GetBucketAcl",
      Resource = "${aws_s3_bucket.cloudtrail_logs.arn}"
    },
    {
        Sid = "AllowOperationAndManagementListBucket",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "arn:aws:iam::${var.management_account_id}:root"
          ]
        },
        Action = [
          "s3:ListBucket"
        ],
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}"
      }
  ]
}
)
}