resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-2a"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

// 엔드포인트 인터페이스용 Security Group
resource "aws_security_group" "allow_endpoint" {
  name   = "endpoint-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # tfsec:ignore:aws-ec2-no-public-egress-sgr
  }
}

// 1-1) S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

// 1-2) KMS Interface Endpoint
resource "aws_vpc_endpoint" "kms" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.allow_endpoint.id]
}

// Lambda 함수용 Security Group
resource "aws_security_group" "allow_lambda" {
  name   = "lambda-security-group"
  vpc_id = aws_vpc.main.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # tfsec:ignore:aws-ec2-no-public-egress-sgr
  }

  egress {
    description = "Allow DNS UDP outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.2/32"]
  }
}

// Slack 도메인만 통과시키는 Stateful 룰 그룹
resource "aws_networkfirewall_rule_group" "slack_domain" {
  name     = "allow-slack-domain"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      rules_source_list {
        # ALLOWLIST 모드: targets에 지정한 도메인만 허용, 나머지는 차단
        generated_rules_type = "ALLOWLIST"
        # 허용할 도메인
        targets = ["hooks.slack.com"]
        # HTTP Host 헤더와 TLS SNI 검사
        target_types = ["HTTP_HOST", "TLS_SNI"]
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}

// 룰 그룹을 연결할 방화벽 정책
resource "aws_networkfirewall_firewall_policy" "policy" {
  name = "monitoring-firewall-policy"

  firewall_policy {
    # Stateless 기본 동작
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    # Stateful 엔진 순서 설정 (STRICT_ORDER 또는 DEFAULT_ACTION_ORDER)
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    # Stateful 기본 동작 — “drop” 대신 AWS-접두사 액션을 사용해야 합니다
    stateful_default_actions = ["aws:drop_strict"]

    # Slack 도메인 허용 룰 그룹 (priority 필수)
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.slack_domain.arn
      priority     = 1
    }
  }
}

// 방화벽 자체를 VPC에 배치 (프라이빗 서브넷)
resource "aws_networkfirewall_firewall" "fw" {
  name                = "monitoring-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy.arn
  vpc_id              = aws_vpc.main.id

  subnet_mapping {
    subnet_id = aws_subnet.private.id
  }
}