#index 템플릿 정의
resource "null_resource" "opensearch_index_template" {
  provisioner "local-exec" {
    command = <<EOT
    curl -X PUT "https://${aws_opensearch_domain.siem.endpoint}/_index_template/lambda-logs-template" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $(aws sts get-session-token --query 'Credentials.SessionToken' --output text)" \
      -d '{
        "index_patterns": ["lambda-logs-*"],
        "template": {
          "mappings": {
            "properties": {
              "timestamp": { "type": "date" },
              "level":     { "type": "keyword" },
              "service":   { "type": "keyword" },
              "message":   { "type": "text" },
              "user":      { "type": "keyword" }
            }
          }
        },
        "priority": 1
      }'
    EOT
  }

  depends_on = [aws_opensearch_domain.siem]
}
