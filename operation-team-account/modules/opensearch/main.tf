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
    enforce_https           = true
    tls_security_policy     = "Policy-Min-TLS-1-2-2019-07"
    custom_endpoint_enabled = false
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = var.basic_auth_user
      master_user_password = var.basic_auth_pass
    }
  }

  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  access_policies = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "es:*",
        Resource  = "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/siem-${var.domain_name}/*",
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "0.0.0.0/0" # ⚠️ 보안상 테스트용. 운영 시엔 회사 IP로 제한해야 합니다.
          }
        }
      }
    ]
  })

  tags = {
    Name        = "siem-opensearch"
    Environment = "dev"
    Owner       = "monitoring-team"
  }
}

# 현재 계정 정보 가져오기 위한 data block
data "aws_caller_identity" "current" {}

output "endpoint" {
  value = aws_opensearch_domain.siem.endpoint
}
