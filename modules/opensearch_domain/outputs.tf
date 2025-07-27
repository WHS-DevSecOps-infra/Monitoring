output "endpoint" {
  value     = aws_opensearch_domain.this.endpoint
  sensitive = true
}