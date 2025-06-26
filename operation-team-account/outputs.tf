output "opensearch_endpoint" {
  description = "Endpoint URL of the OpenSearch domain"
  value       = module.opensearch.endpoint
}

output "cloudtrail_status" {
  description = "CloudTrail logging status"
  value       = module.cloudtrail.status
}
