variable "domain_name"           { type = string }
variable "engine_version"        { type = string }
variable "cluster_instance_type" { type = string }
variable "cluster_instance_count"{ type = number }
variable "ebs_volume_size"       { type = number }
variable "kms_key_arn"           { type = string }

resource "aws_opensearch_domain" "siem" {
  domain_name    = "siem-${var.domain_name}"
  engine_version = var.engine_version

  cluster_config {
    instance_type  = var.cluster_instance_type
    instance_count = var.cluster_instance_count
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Name        = "siem-opensearch"
    Environment = "dev"
    Owner       = "monitoring-team"
  }
}

output "endpoint" {
  value = aws_opensearch_domain.siem.endpoint
}

output "domain_arn" {
  value = aws_opensearch_domain.siem.arn
}