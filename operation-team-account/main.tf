module "s3" {
  source = "./modules/s3"
}

module "opensearch" {
  source            = "./modules/opensearch"
  sso_role_name     = var.sso_role_name
  sso_user_name     = var.sso_user_name
  firehose_role_arn = module.firehose.firehose_role_arn
}

module "firehose" {
  source                = "./modules/firehose"
  opensearch_domain_arn = module.opensearch.domain_arn
  s3_bucket_arn         = module.s3.bucket_arn
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  subscription_filter_name = "cw-to-firehose"
  log_group_name           = var.log_group_name
  firehose_arn             = module.firehose.delivery_stream_arn
  role_arn                 = module.firehose.firehose_role_arn
}
module "securitylake" {
  source = "./modules/securitylake"
}
