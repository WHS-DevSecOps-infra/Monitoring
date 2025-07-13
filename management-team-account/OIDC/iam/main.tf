# modules/github_oidc를 불러와 해당account별 OIDC역할을 자동으로 생성하는 구조

module "github_oidc" {
  source = "../../../modules/github_oidc"

  role_name = "management-role"

  # GitHub Actions에서 이 role을 사용할 수 있도록 허용하는 sub조건
  sub_condition = ["repo:WHS-DevSecOps-infra/Organization:*",
  "repo:WHS-DevSecOps-infra/Monitoring:*"]

  thumbprint_list = ["d89e3bd43d5d909b47a18977aa9d5ce36cee184c"]

  # 이 role에 연결할 정책들(IAM 정책 ARN)
  policy_arns = []
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "custom_inline_policy" {
  name = "management"
  role = module.github_oidc.oidc_role_name # 모듈에서 출력된 role이름 참조

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
          "dynamoDB:*",
          "kms:*",
          "iam:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}
