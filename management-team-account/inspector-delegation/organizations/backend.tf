terraform {
  backend "s3" {
    bucket         = "cloudfence-management-state"
    key            = "inspector-delegation/organizations.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "s3-management-lock"
  }
}