variable "sso_role_name" {
  description = "SSO에서 부여된 IAM 역할 이름"
  type        = string
}

variable "sso_user_name" {
  description = "SSO 세션 사용자 이름"
  type        = string
}

variable "log_group_name" {
  description = "전송할 CloudWatch Log Group 이름"
  type        = string
}
