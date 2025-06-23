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