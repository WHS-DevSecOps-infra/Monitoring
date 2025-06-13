module "s3" {
  source = "./modules/s3"
}

module "opensearch" {
  source = "./modules/opensearch"
}

module "firehose" {
  source               = "./modules/firehose"
  opensearch_domain_arn = module.opensearch.domain_arn
  s3_bucket_arn         = module.s3.bucket_arn
}

module "cloudwatch_logs_to_firehose" {
  source = "./modules/cloudwatch_logs_to_firehose"

  subscription_filter_name = "cw-to-firehose"
  log_group_name           = var.log_group_name
  firehose_arn             = var.firehose_arn
  role_arn                 = var.role_arn
}
module "securitylake" {
  source = "./modules/securitylake"
}
