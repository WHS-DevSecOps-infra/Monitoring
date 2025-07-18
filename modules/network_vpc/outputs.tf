output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "security_group_id" {
  value = aws_security_group.allow_lambda.id
}

output "opensearch_sg_id" {
  description = "Opensearch 접근을 허용하는 Security Group ID"
  value       = aws_security_group.opensearch_sg.id
}