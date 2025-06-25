output "delivery_stream_arn" {
  value       = aws_kinesis_firehose_delivery_stream.to_opensearch.arn
  description = "ARN of the Firehose delivery stream"
}

output "firehose_role_arn" {
  value       = aws_iam_role.firehose_role.arn
  description = "ARN of the Firehose IAM role"
}
