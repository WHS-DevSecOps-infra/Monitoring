variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "org_trail_name" {
  description = "Organization CloudTrail 이름"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "Operation 계정에서 생성된 CloudTrail 로그용 S3 버킷 이름"
  type        = string
}