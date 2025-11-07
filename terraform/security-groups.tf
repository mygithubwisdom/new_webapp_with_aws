//Security Groups - Network Traffic Control

# 1. Bastion Host Security Group (SSH Jump Server)
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for SSH bastion/jump server"
  vpc_id      = aws_vpc.main-webapp.id

  # SSH from MY LAPTOP ONLY
  ingress {
    description = "SSH from your laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.SSH_laptop_ip] # Example: "203.0.113.45/32"
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# 2. Web Server Security Group

# Security Group for EC2  
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main-webapp.id

  # SSH from Bastion Host ONLY
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id] //[var.allowed_ssh_cidr] # Only my IP
  }

  # HTTP from YOUR LAPTOP (for testing)
  ingress {
    description = "HTTP from your laptop"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.SSH_laptop_ip] # Only your IP
  }

  # HTTP from INTERNET (for public access)
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Public access
  }

  # Https access Node.js app port (development/testing)
  ingress {
    description = "Node App"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //[var.SSH_laptop_ip]  # Only your IP
  }

  # HTTPS (for production)
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All other Outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Create a NACL for the Public Subnet
resource "aws_network_acl" "PublicSubnetNACL" {
  vpc_id = aws_vpc.main-webapp.id

  tags = {
    Name = var.public_nacl_name
  }
}

# NACL rules for public subnet
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

resource "aws_network_acl_rule" "PublicInboundSSH" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.allowed_ssh_cidr # use the allowed SSH CIDR variable (e.g. your-ip/32)
  from_port      = var.ssh_port
  to_port        = var.ssh_port
}

# NACL rules for public subnet (Added Rule)
resource "aws_network_acl_rule" "PublicInboundNodeApp" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 130 # Next rule number
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 3000
  to_port        = 3000
}

# Allow all outbound traffic
resource "aws_network_acl_rule" "PublicOutbound" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 200
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# Create a NACL for the Private Subnet
resource "aws_network_acl" "PrivateSubnetNACL" {
  vpc_id = aws_vpc.main-webapp.id
}

# Allow inbound traffic from the public subnet
resource "aws_network_acl_rule" "PrivateInboundFromPublic" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.public_subnet_cidr
  from_port      = 0
  to_port        = 65535
}

# Allow outbound traffic to the public subnet
resource "aws_network_acl_rule" "PrivateOutboundToPublic" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = var.public_subnet_cidr //"aws_vpc.foo.cidr_block
  from_port      = 0
  to_port        = 65535
}

# Allow outbound traffic to the internet
resource "aws_network_acl_rule" "PrivateOutboundToInternet" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 210
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

// 3. Security Group (Private Subnet)

resource "aws_security_group" "app_server" {
  name        = "${var.project_name}-app-server-sg"
  description = "Security group for application server"
  vpc_id      = aws_vpc.main-webapp.id

  # SSH from Bastion ONLY
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # App traffic from Web Server
  ingress {
    description     = "App port from Web Server"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-server-sg"
  }
}


