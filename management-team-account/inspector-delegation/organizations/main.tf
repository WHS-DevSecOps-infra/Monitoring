resource "aws_inspector2_delegated_admin_account" "this" {
  account_id = var.operation_account_id
}