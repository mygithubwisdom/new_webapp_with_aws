# 1. SECURITY GROUPS (The State-aware "Locks")
# ==========================================================

# --- ALB Security Group (Public Facing) ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main-webapp.id

  ingress {
    description = "Public HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Allow ALB to send traffic to App Servers on the Node Port
  egress {
    description = "Forward traffic to app servers"
    from_port   = var.node_app_port
    to_port     = var.node_app_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main-webapp.cidr_block]
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

  # Outbound: Database (To RDS in Private Subnet)
  egress {
    description = "Allow traffic to RDS"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main-webapp.cidr_block]
  }

  tags = {
    Name        = "${var.project_name}-app-sg-prod"
    Environment = var.environment
  }
}

# ==========================================================
# 2. NETWORK ACLS (The Stateless "Firewalls")

# --- PUBLIC SUBNET NACL (For ALB) ---
resource "aws_network_acl" "PublicSubnetNACL" {
  vpc_id = aws_vpc.main-webapp.id
  tags   = { Name = "${var.project_name}-public-nacl" }
}

resource "aws_network_acl_rule" "PublicInboundHTTPS" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "PublicInboundEphemeral" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "PublicOutboundAll" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 200
  protocol       = "-1" # Allows all outbound for simplicity at NACL level
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# --- PRIVATE SUBNET NACL (For App Servers) ---
resource "aws_network_acl" "PrivateSubnetNACL" {
  vpc_id = aws_vpc.main-webapp.id
  tags   = { Name = "${var.project_name}-private-nacl" }
}

resource "aws_network_acl_rule" "PrivateInboundFromALB" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.public_subnet_cidr
  from_port      = var.node_app_port
  to_port        = var.node_app_port
}

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