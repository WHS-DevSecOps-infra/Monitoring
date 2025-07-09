# modules/github_oidc를 불러와 해당account별 OIDC역할을 자동으로 생성하는 구조




module "github_oidc" {
  source = "../../../modules/github_oidc"

  role_name = "operation-cicd"

  # GitHub Actions에서 이 role을 사용할 수 있도록 허용하는 sub조건
  sub_condition = "repo:WHS-DevSecOps-infra/Monitoring:*"


  # 이 role에 연결할 정책들(IAM 정책 ARN)
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess",
    "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS",
    "arn:aws:iam::aws:policy/AWSWAFFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "custom_inline_policy" {
  name = "operation-cicd"
  role = module.github_oidc.oidc_role_name # 모듈에서 출력된 role이름 참조

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:*",
          "sts:AssumeRole"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:*",
          "cloudtrail:*"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "KMSAccess",
        "Effect" : "Allow",
        "Action" : [
          "kms:*"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "DynamoDBAccess",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}