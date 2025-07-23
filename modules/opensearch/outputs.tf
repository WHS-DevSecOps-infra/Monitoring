output "domain_name" {
  description = "Name of the OpenSearch domain"
  value       = aws_opensearch_domain.siem.domain_name
}

output "domain_endpoint" {
  description = "Endpoint of the OpenSearch domain"
  value       = aws_opensearch_domain.siem.endpoint
}

output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.siem.arn
}

output "endpoint" {
  value = aws_opensearch_domain.siem.endpoint
}