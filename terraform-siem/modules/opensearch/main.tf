data "aws_caller_identity" "current" {}

resource "aws_opensearch_domain" "siem" {
  domain_name     = "siem-domain"
  engine_version  = "OpenSearch_2.9"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled = true
  }

    access_policies = jsonencode({
      Version = "2012-10-17",
      Statement = [
       {
         Effect = "Allow",
         Principal = {
            AWS = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${var.sso_role_name}/${var.sso_user_name}"
          },
         Action   = "es:*",
         Resource = "arn:aws:es:ap-northeast-2:${data.aws_caller_identity.current.account_id}:domain/siem-domain/*"
        }
      ]
    })
}
