#현재 계정정보를 가져옴
data "aws_caller_identity" "current" {}


provider "aws" {
  region = "ap-northeast-2"

}


# GitHub Actions용 OIDC provider 설정
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com" # OIDC에서 사용할 클라이언트 ID
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" # GitHub 공식 인증서 지문 thumbprint(공식값)
  ]
}

# oidc_role 이라는 이름의 IAM Role
resource "aws_iam_role" "oidc_role" {
  name = var.role_name # 생성할 Role 이름

  # GitHub에서 이 역할을 assume할 수 있게 설정
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn # 위에서 만든 OIDC Provider의 ARN
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            # 어떤 GitHub repo에서만 이 Role을 사용할 수 있는지 제어
            "token.actions.githubusercontent.com:sub" : var.sub_condition
          }
        }
      }
    ]
  })
}