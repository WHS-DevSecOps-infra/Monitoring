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
