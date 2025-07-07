output "management_account_id" {
  description = "Account ID of the management account"
  value       = data.aws_caller_identity.current.account_id
}

output "debug_cloudtrail_s3_bucket_name" {
  value = data.terraform_remote_state.operation.outputs.bucket_name
}

output "debug_cloudtrail_kms_key_arn" {
  value = data.terraform_remote_state.operation.outputs.kms_key_arn
}