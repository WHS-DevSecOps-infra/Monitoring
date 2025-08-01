# modules/github_oidc를 불러와 해당account별 OIDC역할을 자동으로 생성하는 구조




module "github_oidc" {
  source = "../../../modules/iam_OIDC"

  role_name      = "operation-cicd"
  account_id     = "502676416967"
  add_root_trust = true


  # GitHub Actions에서 이 role을 사용할 수 있도록 허용하는 sub조건
  sub_condition = ["repo:WHS-DevSecOps-infra/Organization:*",
    "repo:WHS-DevSecOps-infra/Monitoring:*",
    "repo:WHS-DevSecOps-infra/Application-Deployment:*",
  "repo:yunhoch0i/Application-Deployment:*"]
  thumbprint_list = ["d89e3bd43d5d909b47a18977aa9d5ce36cee184c"]

  # 이 role에 연결할 정책들(IAM 정책 ARN)
  policy_arns = []



}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "custom_inline_policy" {
  name = "operation-cicd"
  role = module.github_oidc.oidc_role_name # 모듈에서 출력된 role이름 참조

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:*",
          "sts:AssumeRole",
          "events:*",
          "es:*",
          "lambda:*",
          "inspector2:*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      },
      {
        "Action" : [
          "cloudwatch:*",
          "cloudtrail:*"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" : [
          "kms:*"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "KMSAccess"
      },
      {
        "Action" : [
          "dynamodb:*"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "DynamoDBAccess"
      },
      {
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::cloudfence-operation-state",
          "arn:aws:s3:::cloudfence-operation-state/*"
        ],
        "Sid" : "TerraformBackendOperationState"
      },
      {
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:dynamodb:*:*:table/s3-operation-lock",
        "Sid" : "TerraformDynamoDBLock"
      },
      {
        "Action" : [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:kms:ap-northeast-2:502676416967:key/9901c9d1-8b00-47a9-bd7a-53cfc1f70d25",
        "Sid" : "KMSAccessForState"
      },
      {
        "Action" : [
          "ecr:*",
          "iam:CreateServiceLinkedRole"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "ECRAndIAMManagement"
      }
    ]
    }
  )
}
