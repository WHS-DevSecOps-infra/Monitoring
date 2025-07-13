terraform {
  backend "s3" {
    bucket         = "cloudfence-management-state"
    key            = "s3/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "s3-management-lock"
  }
}
