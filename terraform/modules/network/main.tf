# VPC for our infrastructure
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-vpc-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
}

# VPN Gateway
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-vpn-gateway-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
}

# Customer Gateway
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = var.customer_ip
  type       = "ipsec.1"

  tags = {
    Name        = "${var.project}-customer-gateway-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
}

# VPN Connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name        = "${var.project}-vpn-connection-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
}

# Security Group for VPN traffic
resource "aws_security_group" "vpn" {
  name        = "${var.project}-vpn-sg-${var.environment}"
  description = "Security group for VPN traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.customer_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-vpn-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
} 