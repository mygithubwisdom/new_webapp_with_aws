# NETWORK OUTPUTS

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main-webapp.id
}

output "public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.example.public_ip
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.static_content.id
}

# CloudWatch Outputs
output "vpc_flow_log_group" {
  description = "VPC Flow Logs CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "ssh_alarm_name" {
  description = "SSH connections alarm name"
  value       = aws_cloudwatch_metric_alarm.ssh_alert.alarm_name
}

output "flow_log_iam_role_arn" {
  description = "IAM role ARN for VPC Flow Logs"
  value       = aws_iam_role.vpc_flow_logs.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}