
provider "aws" {
  region = "ap-northeast-2"

}
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com" # OIDC에서 사용할 클라이언트 ID
  ]

  thumbprint_list = var.thumbprint_list
}

resource "aws_iam_role" "oidc_role" {
  name        = var.role_name
  description = "cicd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        {
          Effect = "Allow",
          Principal = {
            Federated = aws_iam_openid_connect_provider.github.arn
          },
          Action = "sts:AssumeRoleWithWebIdentity",
          Condition = {
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            },
            StringLike = {
              "token.actions.githubusercontent.com:sub" = var.sub_condition
            }
          }
        }
      ],
      var.add_root_trust ? [
        {
          Effect = "Allow",
          Principal = {
            AWS = "arn:aws:iam::${var.account_id}:root"
          },
          Action = "sts:AssumeRole"
        }
      ] : []
    )

  })
}
