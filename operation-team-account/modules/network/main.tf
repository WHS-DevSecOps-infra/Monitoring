resource "aws_vpc_endpoint" "opensearch" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.es"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.a.id]
  security_group_ids  = [aws_security_group.lambda_to_opensearch.id]
  private_dns_enabled = true

  tags = {
    Name = "opensearch-vpc-endpoint"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "main-vpc" }
}

resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "subnet-a" }
}

resource "aws_security_group" "lambda_to_opensearch" {
  name        = "lambda-to-opensearch"
  description = "Allow Lambda to access OpenSearch"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "lambda-egress" }
}