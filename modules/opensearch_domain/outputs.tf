output "endpoint" {
  value     = aws_opensearch_domain.this.endpoint
  sensitive = true
}

output "opensearch_domain_id" {
  description = "The ID of the OpenSearch domain"
  value       = aws_opensearch_domain.this.id
  sensitive   = true
}