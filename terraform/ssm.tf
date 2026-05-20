# AWS Systems Manager (SSM) Session Manager Configuration
# ============================================================================ 

# 1. The actual IAM Role
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# VPC Endpoints for SSM (Required for Private Subnet Access)
# ============================================================================

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main-webapp.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg"
  }
}

# # The Primary SSM Interface Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main-webapp.id
  service_name        = "com.amazonaws.us-east-1.ssm" # The missing one
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_sg.id]
  subnet_ids          = [aws_subnet.Privatesubnet_a.id, aws_subnet.Privatesubnet_b.id]
  private_dns_enabled = true
}

# SSM Endpoint
# This provides the "MESSAGES" path for SSM
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main-webapp.id
  service_name        = "com.amazonaws.us-east-1.ssmmessages" # Ensure this matches your provider region
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_sg.id]
  subnet_ids          = [aws_subnet.Privatesubnet_a.id, aws_subnet.Privatesubnet_b.id]
  private_dns_enabled = true
}

# This provides the "EC2" command path
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main-webapp.id
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_sg.id]
  subnet_ids          = [aws_subnet.Privatesubnet_a.id, aws_subnet.Privatesubnet_b.id]
  private_dns_enabled = true
}

# ============================================================================
# CloudWatch Log Group for SSM Session Logs
# ============================================================================

resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/aws/ssm/${var.project_name}/sessions"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-ssm-sessions"
  }
}

# ============================================================================
# SSM Document for Session Logging
# ============================================================================

resource "aws_ssm_document" "session_logging" {
  name            = "${var.project_name}-session-logging"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to hold regional settings for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = ""
      s3KeyPrefix                 = ""
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_sessions.name
      cloudWatchEncryptionEnabled = true
      cloudWatchStreamingEnabled  = true
      idleSessionTimeout          = "20"
      maxSessionDuration          = "60"
      runAsEnabled                = false
      runAsDefaultUser            = ""
    }
  })

  tags = {
    Name = "${var.project_name}-session-logging"
  }
}