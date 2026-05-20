# Data source to get current region
data "aws_region" "current" {}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# KMS Key for SNS encryption
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-sns-kms-key"
    Environment = var.environment
  }
}

# KMS Key Alias for SNS
resource "aws_kms_alias" "sns" {
  name          = "alias/${var.project_name}-sns"
  target_key_id = aws_kms_key.sns.key_id
}

# KMS Key for CloudWatch Logs encryption
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  # Key policy to allow CloudWatch Logs service to use this key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cloudwatch-logs-kms-key"
    Environment = var.environment
  }
}

# KMS Key Alias for CloudWatch Logs
resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${var.project_name}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# SNS Topic for notifications
resource "aws_sns_topic" "alerts" {
  name              = "${var.environment}-${var.project_name}-alerts"
  kms_master_key_id = aws_kms_key.sns.arn

  tags = {
    Name        = "${var.environment}-${var.project_name}-alerts"
    Environment = var.environment
  }
}

# SNS Topic subscription (email)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ============================================================================
# VPC Flow Logs IAM Role
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-flow-logs-role"
  }
}

# IAM Policy for Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.project_name}"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

# CloudWatch Log Group for Webapp Logs
resource "aws_cloudwatch_log_group" "webapp_logs" {
  name              = "/aws/ec2/terraform-aws-webapp-setup"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = {
    Name        = "${var.project_name}-webapp-logs"
    Environment = var.environment
  }
}


# VPC Flow Log
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main-webapp.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  tags = {
    Name = "${var.project_name}-vpc-flow-log"
  }
}

# Metric Filter for SSH Connections
resource "aws_cloudwatch_log_metric_filter" "ssh_connections" {
  name           = "${var.project_name}-ssh-connections"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport=22, protocol=6, packets, bytes, start, end, action=ACCEPT, log_status]"

  metric_transformation {
    name      = "SSHConnectionCount"
    namespace = "${var.project_name}/VPC"
    value     = "1"
  }
}