variable "sso_role_name" {
  description = "SSO에서 부여된 IAM 역할 이름"
  type        = string
}

variable "sso_user_name" {
  description = "SSO 세션 사용자 이름 (예: 이메일)"
  type        = string
}

variable "firehose_role_arn" {
  description = "ARN of the Firehose IAM role to allow write access"
  type        = string
}

