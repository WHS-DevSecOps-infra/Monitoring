output "opensearch_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.opensearch.id
  description = "The ID of the VPC endpoint for OpenSearch"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [aws_subnet.a.id]
}

output "security_group_ids" {
  value = [aws_security_group.lambda_to_opensearch.id]
}