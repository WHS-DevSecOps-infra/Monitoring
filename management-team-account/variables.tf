variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "org_trail_name" {
  description = "Organization CloudTrail name"
  type        = string
  default     = "org-cloudtrail"
}