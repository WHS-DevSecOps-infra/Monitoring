output "management_account_id" {
  description = "Account ID of the management account"
  value       = data.aws_caller_identity.current.account_id
}