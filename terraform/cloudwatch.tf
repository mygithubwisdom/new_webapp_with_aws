# Data source to get current region
data "aws_region" "current" {}

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

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.example.id],
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.example.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.example.id],
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.example.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "EC2 Instance Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          query  = "SOURCE '/aws/ec2/${var.project_name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          region = "us-east-1"
          title  = "Application Logs"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization exceeds 80%" #"This metric monitors ec2 cpu utilization"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts.arn] : []
  ok_actions          = var.notification_email != "" ? [aws_sns_topic.alerts.arn] : []



  dimensions = {
    InstanceId = aws_instance.example.id
  }

  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${var.project_name}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 status check failed"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts.arn] : []

  dimensions = {
    InstanceId = aws_instance.example.id
  }

  tags = {
    Name = "${var.project_name}-status-alarm"
  }
}

# CloudWatch Alarms

# High Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "2" # 2 seconds
  alarm_description   = "This metric monitors application response time"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts.arn] : []
  ok_actions          = var.notification_email != "" ? [aws_sns_topic.alerts.arn] : []

  dimensions = {
    InstanceId = aws_instance.example.id
  }

  tags = {
    Name        = "${var.environment}-high-response-time-alarm"
    Environment = var.environment
  }
}

# Network Monitor for EC2 Health Monitoring
resource "aws_networkmonitor_monitor" "webapp" {
  aggregation_period = 60
  monitor_name       = "${var.project_name}-network-monitor"

  tags = {
    Name        = "${var.project_name}-monitor"
    Environment = var.environment
  }
}

# Probe to monitor EC2 instance health
resource "aws_networkmonitor_probe" "ec2_health" {
  monitor_name     = aws_networkmonitor_monitor.webapp.monitor_name
  destination      = aws_instance.example.private_ip
  destination_port = 3000
  protocol         = "TCP"
  source_arn       = aws_subnet.Publicsubnet.arn
  packet_size      = 56

  tags = {
    Name   = "${var.project_name}-ec2-probe"
    Target = "EC2-NodeApp"
  }
}

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
  name              = "/aws/vpc/flow-logs/Terraform-AWS-webapp-Setup"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = {
    Name = "Terraform-AWS-webapp-Setup-vpc-flow-logs"
  }
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

# Alarm for SSH Connections
resource "aws_cloudwatch_metric_alarm" "ssh_alert" {
  alarm_name          = "${var.project_name}-ssh-connections-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SSHConnectionCount"
  namespace           = "${var.project_name}/VPC"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when SSH connections exceed 10 in 5 minutes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts.arn] : []

  tags = {
    Name = "${var.project_name}-ssh-alarm"
  }
}