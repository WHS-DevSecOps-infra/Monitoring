resource "null_resource" "import_saved_query" {
  provisioner "local-exec" {
    command = <<EOT
curl -X POST "${aws_opensearch_domain.siem.endpoint}/_dashboards/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  --form file=@${path.module}/saved_queries/root-login.ndjson
EOT
  }

  depends_on = [aws_opensearch_domain.siem]
}

resource "null_resource" "import_s3_query" {
  provisioner "local-exec" {
    command = <<EOT
curl -X POST "${aws_opensearch_domain.siem.endpoint}/_dashboards/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  --form file=@${path.module}/saved_queries/s3-public-acl.ndjson
EOT
  }

  depends_on = [aws_opensearch_domain.siem]
}

resource "null_resource" "ism_policy" {
  provisioner "local-exec" {
    command = <<EOT
curl -X PUT "${aws_opensearch_domain.siem.endpoint}/_plugins/_ism/policies/delete-after-30d" \
  -H "Content-Type: application/json" \
  -d @${path.module}/ism/delete-after-30d.json
EOT
  }

  depends_on = [aws_opensearch_domain.siem]
}
