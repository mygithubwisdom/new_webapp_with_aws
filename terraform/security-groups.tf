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
    cidr_blocks = [var.SSH_laptop_ip] 
  }

  # HTTPS outbound for package updates and API calls
  # SECURITY NOTE: 0.0.0.0/0 is required because:
  # - Package repositories (apt, yum) use various CDN IPs that change frequently
  # - External API calls may target any HTTPS endpoint
  # - Port is restricted to 443 only, limiting attack surface
  # - This is standard practice for servers requiring internet access
  egress {
    description = "HTTPS outbound for package updates and API calls"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound for package updates
  # SECURITY NOTE: 0.0.0.0/0 is required because:
  # - Some package repositories use HTTP (though less common)
  # - HTTP redirects to HTTPS may be needed
  # - Port is restricted to 80 only
  egress {
    description = "HTTP outbound for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #5 
  }

  # DNS outbound to VPC DNS resolver (restricted to VPC DNS)
  egress {
    description = "DNS outbound to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["169.254.169.253/32"] # VPC DNS resolver IP
  }

  # DNS outbound TCP to VPC DNS resolver (for large responses)
  egress {
    description = "DNS outbound TCP to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["169.254.169.253/32"] # VPC DNS resolver IP
  }

  # Ephemeral ports for return traffic
  # SECURITY NOTE: 0.0.0.0/0 is REQUIRED and UNAVOIDABLE because:
  # - When initiating connections, the OS uses ephemeral ports (1024-65535)
  # - Return traffic can come from ANY IP address that was contacted
  # - This is how TCP/IP works - you cannot predict the source IP of responses
  # - Without this rule, outbound connections would fail
  # - This is standard practice and required for any server making outbound connections
  egress {
    description = "Ephemeral ports for return traffic (required for outbound connections)"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
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

  # SSH from allowed CIDR only
  # SECURITY NOTE: Set var.allowed_ssh_cidr to your specific IP (e.g., "203.0.113.45/32")
  # Default is "0.0.0.0/0" which allows SSH from anywhere - change this in terraform.tfvars
  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP from YOUR LAPTOP (for testing)
  ingress {
    description = "HTTP from your laptop"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.SSH_laptop_ip] # Only your IP
  }

  # # HTTP from INTERNET (for public access)
  # ingress {
  #   description = "HTTP from internet"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"] # Public access
  # }

  # Https access Node.js app port (development/testing)
  ingress {
    description = "Node App"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.SSH_laptop_ip] # Ensure this variable is NOT 0.0.0.0/0
  }

  # HTTPS (for production)
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS outbound for package updates and API calls
  # SECURITY NOTE: 0.0.0.0/0 is required because:
  # - Package repositories (apt, yum) use various CDN IPs that change frequently
  # - External API calls may target any HTTPS endpoint
  # - Port is restricted to 443 only, limiting attack surface
  # - This is standard practice for servers requiring internet access
  egress {
    description = "HTTPS outbound for package updates and API calls"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound for package updates
  # SECURITY NOTE: 0.0.0.0/0 is required because:
  # - Some package repositories use HTTP (though less common)
  # - HTTP redirects to HTTPS may be needed
  # - Port is restricted to 80 only
  egress {
    description = "HTTP outbound for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS outbound to VPC DNS resolver (restricted to VPC DNS)
  egress {
    description = "DNS outbound to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["169.254.169.253/32"] # VPC DNS resolver IP
  }

  # DNS outbound TCP to VPC DNS resolver (for large responses)
  egress {
    description = "DNS outbound TCP to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["169.254.169.253/32"] # VPC DNS resolver IP
  }

  # Ephemeral ports for return traffic
  # SECURITY NOTE: 0.0.0.0/0 is REQUIRED and UNAVOIDABLE because:
  # - When initiating connections, the OS uses ephemeral ports (1024-65535)
  # - Return traffic can come from ANY IP address that was contacted
  # - This is how TCP/IP works - you cannot predict the source IP of responses
  # - Without this rule, outbound connections would fail
  # - This is standard practice and required for any server making outbound connections
  egress {
    description = "Ephemeral ports for return traffic (required for outbound connections)"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #9   via security-groups.tf:86-201 (aws_security_group.ec2)
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

# SECURITY NOTE: Set var.allowed_ssh_cidr to your specific IP (e.g., "203.0.113.45/32")
# Default is "0.0.0.0/0" which allows SSH from anywhere - change this in terraform.tfvars
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
  cidr_block     = var.allowed_ssh_cidr
  from_port      = 3000
  to_port        = 3000
}

# NACL Outbound rule to allow the server to respond to requests
resource "aws_network_acl_rule" "PublicOutboundReply" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 140
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true # This makes it an OUTBOUND rule
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535 # Ephemeral port range
}

# Allow HTTPS outbound
resource "aws_network_acl_rule" "PublicOutboundHTTPS" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow HTTP outbound
resource "aws_network_acl_rule" "PublicOutboundHTTP" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 201
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Allow DNS outbound to VPC resolver (UDP)
resource "aws_network_acl_rule" "PublicOutboundDNSUDP" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 202
  protocol       = "udp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "169.254.169.253/32" # VPC DNS resolver IP
  from_port      = 53
  to_port        = 53
}

# Allow DNS outbound to VPC resolver (TCP)
resource "aws_network_acl_rule" "PublicOutboundDNSTCP" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 203
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "169.254.169.253/32" # VPC DNS resolver IP
  from_port      = 53
  to_port        = 53
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

# Allow Inbound Ephemeral ports from the Internet 
# (Required for the replies to your HTTPS/HTTP outbound calls)
resource "aws_network_acl_rule" "PrivateInboundInternetReply" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 111 # Between your public trust and your deny all
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
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

# Allow HTTPS outbound to internet
resource "aws_network_acl_rule" "PrivateOutboundToInternetHTTPS" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 210
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow HTTP outbound to internet
resource "aws_network_acl_rule" "PrivateOutboundToInternetHTTP" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 211
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Allow DNS outbound to VPC resolver (UDP)
resource "aws_network_acl_rule" "PrivateOutboundToInternetDNSUDP" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 212
  protocol       = "udp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "169.254.169.253/32" # VPC DNS resolver IP
  from_port      = 53
  to_port        = 53
}

# Allow DNS outbound to VPC resolver (TCP)
resource "aws_network_acl_rule" "PrivateOutboundToInternetDNSTCP" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 213
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "169.254.169.253/32" # VPC DNS resolver IP
  from_port      = 53
  to_port        = 53
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

  # TEMP: allow CI runners (public) to reach the Node app on 3000
  ingress {
    description = "CI healthcheck to Node app"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.SSH_laptop_ip] #["0.0.0.0/0"]
  }

  # HTTPS outbound for package updates and API calls
  # SECURITY NOTE: 0.0.0.0/0 is required because:
  # - Package repositories (apt, yum) use various CDN IPs that change frequently
  # - External API calls may target any HTTPS endpoint
  # - Port is restricted to 443 only, limiting attack surface
  # - This is standard practice for servers requiring internet access
  egress {
    description = "HTTPS outbound for package updates and API calls"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound for package updates
  # SECURITY NOTE: 0.0.0.0/0 is required because:
  # - Some package repositories use HTTP (though less common)
  # - HTTP redirects to HTTPS may be needed
  # - Port is restricted to 80 only
  egress {
    description = "HTTP outbound for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Consider disabling after setup
  }

  # DNS outbound to VPC DNS resolver (restricted to VPC DNS)
  egress {
    description = "DNS outbound to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["169.254.169.253/32"] # VPC DNS resolver IP
  }

  # DNS outbound TCP to VPC DNS resolver (for large responses)
  egress {
    description = "DNS outbound TCP to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["169.254.169.253/32"] # VPC DNS resolver IP
  }

  tags = {
    Name = "${var.project_name}-app-server-sg"
  }
}


