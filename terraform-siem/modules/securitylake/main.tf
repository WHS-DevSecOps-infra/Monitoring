resource "aws_security_lake" "this" {
  enable_all = true
}

resource "aws_security_lake_organization_configuration" "org_config" {
  auto_enable = {
    all_regions = true
  }
}
