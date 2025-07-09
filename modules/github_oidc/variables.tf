variable "role_name" {
  type        = string
  description = "OIDC 역할 이름"
}

variable "sub_condition" {
  type        = string
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
