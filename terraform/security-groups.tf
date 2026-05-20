# 1. SECURITY GROUPS (The State-aware "Locks")

# --- ALB Security Group (Public Facing) ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main-webapp.id

  # ingress {
  #   description = "Public HTTPS Access"    #7
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description = "Public HTTP Access (Optional, can be removed for strict HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ALB to send traffic to App Servers on the Node Port
  egress {
    description = "Forward traffic to app servers"
    from_port   = var.node_app_port
    to_port     = var.node_app_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main-webapp.cidr_block] #5 aws_security_group.alb_sg.id
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# --- App Server Security Group (Private) ---
resource "aws_security_group" "app_server" {
  name        = "${var.project_name}-app-sg-prod"
  description = "Production Security Group for Express App - Private Subnet"
  vpc_id      = aws_vpc.main-webapp.id

  # Inbound: ONLY Web traffic from the ALB
  ingress {
    description     = "Node.js app port from ALB"
    from_port       = var.node_app_port
    to_port         = var.node_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Outbound: HTTPS (Required for SSM, OS updates, and API calls)
  egress {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0 #6
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-app-sg-prod"
    Environment = var.environment
  }
}

# ==========================================================
# PRIVATE SUBNET NACL (For App Servers) - REFIXED TO handle 502 gateway failure
# ==========================================================

resource "aws_network_acl" "PrivateSubnetNACL" {
  vpc_id = aws_vpc.main-webapp.id
  tags   = { Name = "${var.project_name}-private-nacl" }
}

# Rule 100: Allow Node.js traffic from Public Subnet A (ALB)
resource "aws_network_acl_rule" "PrivateInboundFromPublicA" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.public_subnet_cidr # 10.0.1.0/24  adjustment for 502 error
  from_port      = 0
  to_port        = 65535
}

# Rule 105: Allow Node.js traffic from Public Subnet B (ALB) - CRITICAL FIX
resource "aws_network_acl_rule" "PrivateInboundFromPublicB" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 105
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.public_subnet_b_cidr
  from_port      = 0
  to_port        = 65535
}

# Rule 110: Allow ephemeral ports (for return traffic)
resource "aws_network_acl_rule" "PrivateInboundEphemeral" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Rule 200: Allow all outbound (NACLs are stateless)
resource "aws_network_acl_rule" "PrivateOutboundAll" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 200
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Associate Private NACL with Private Subnets
resource "aws_network_acl_association" "Privatesubnet_a" {
  subnet_id      = aws_subnet.Privatesubnet_a.id
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
}

resource "aws_network_acl_association" "Privatesubnet_b" {
  subnet_id      = aws_subnet.Privatesubnet_b.id
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
}

# PUBLIC SUBNET NACL
# ============================================================================

resource "aws_network_acl" "PublicSubnetNACL" {
  vpc_id = aws_vpc.main-webapp.id
  tags   = { Name = "${var.project_name}-public-nacl" }
}

# Allow HTTP inbound
resource "aws_network_acl_rule" "PublicInboundHTTP" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Allow HTTPS inbound
resource "aws_network_acl_rule" "PublicInboundHTTPS" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow ephemeral ports inbound (for return traffic)
resource "aws_network_acl_rule" "PublicInboundEphemeral" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow all outbound
resource "aws_network_acl_rule" "PublicOutboundAll" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 200
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Associate Public NACL with Public Subnets
resource "aws_network_acl_association" "Publicsubnet" {
  subnet_id      = aws_subnet.Publicsubnet.id
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
}

resource "aws_network_acl_association" "Publicsubnet_b" {
  subnet_id      = aws_subnet.Publicsubnet_b.id
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
}

# ============================================================================
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main-webapp.id

  # Allow DB access from app servers only
  ingress {
    description     = "DB access from app servers"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_server.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main-webapp.cidr_block]
  }

  tags = {
    Name        = "${var.project_name}-db-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ssm_sg" {
  name        = "${var.project_name}-ssm-sg"
  vpc_id      = aws_vpc.main-webapp.id
  description = "Security group for SSM VPC Endpoint"
  ingress {
    description     = "Allow SSM traffic from app servers"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app_server.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}