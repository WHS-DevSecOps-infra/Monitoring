# 1. 메타스토어 관리자 IAM 역할 생성
resource "aws_iam_role" "securitylake_manager" {
  name = "securitylake-meta-store-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "securitylake.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# 2. 조직 단위 Security Lake 활성화 (조직 전체 설정)
resource "aws_securitylake_organization_configuration" "org_config" {
  auto_enable {
    all_regions = false
    regions     = ["ap-northeast-2"]
  }
}

# 3. 특정 리전(ap-northeast-2)에서 Data Lake 활성화 및 라이프사이클 설정
resource "aws_securitylake_data_lake" "this" {
  meta_store_manager_role_arn = aws_iam_role.securitylake_manager.arn

  configuration {
    region = "ap-northeast-2"

    lifecycle_configuration {
      expiration {
        days = 30 # 데이터 30일 보관
      }
      transition {
        days          = 7
        storage_class = "ONEZONE_IA" # 7일 후 저비용 스토리지로 전환
      }
    }
  }
}
