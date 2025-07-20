variable "role_name" {
  type        = string
  description = "OIDC 역할 이름"
}

variable "sub_condition" {
  type        = list(string)
  description = "OIDC Subject (sub) 조건"
}

variable "policy_arns" {
  type        = list(string)
  description = "Attach할 IAM 정책 목록"
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.oidc_role.name
  policy_arn = each.value
}

variable "thumbprint_list" {
  description = "OIDC provider thumbprint list"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "add_root_trust" {
  description = "Whether to add root account trust"
  type        = bool
  default     = false
}

variable "account_id" {
  description = "AWS account ID for root trust"
  type        = string
  default     = ""
}

