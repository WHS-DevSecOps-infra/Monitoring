output "oidc_role_name" {
  description = "OIDC로 생성된 IAM Role 이름"
  value       = aws_iam_role.oidc_role.name
}