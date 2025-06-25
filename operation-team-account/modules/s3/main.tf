resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "firehose_backup" {
  bucket        = "siem-firehose-backup-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.firehose_backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "s3_cmk" {
  description             = "KMS key for encrypting Firehose backup S3 bucket"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.firehose_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_cmk.arn
    }
  }
}
