# NETWORK & INFRASTRUCTURE
# ==========================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main-webapp.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer - Use this to access the app"
  value       = aws_lb.main.dns_name
}

output "s3_bucket_name" {
  description = "S3 Bucket Name for static assets"
  value       = aws_s3_bucket.static_content.id
}

# ==========================================
# SECURITY GROUPS (For Verification)

output "app_server_sg_id" {
  description = "The ID of the Private App Server Security Group"
  value       = aws_security_group.app_server.id
}

output "alb_sg_id" {
  description = "The ID of the Public Load Balancer Security Group"
  value       = aws_security_group.alb_sg.id
}

# ==========================================
# DATABASE (RDS)

output "db_endpoint" {
  description = "Database connection address"
  value       = aws_db_instance.db.address
}

output "db_port" {
  description = "Database connection port"
  value       = aws_db_instance.db.port
}

# ==========================================
# SSM & ACCESS

output "ssm_role_arn" {
  description = "IAM Role ARN used by EC2 for SSM access"
  value       = aws_iam_role.ssm_role.arn
}

output "vpc_endpoints" {
  description = "VPC Endpoints ensuring private SSM communication"
  value = {
    ssm         = aws_vpc_endpoint.ssm.id
    ssmmessages = aws_vpc_endpoint.ssmmessages.id
    ec2messages = aws_vpc_endpoint.ec2messages.id
  }
}

# MONITORING & LOGGING

output "vpc_flow_log_group" {
  description = "VPC Flow Logs Log Group"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for system alerts"
  value       = aws_sns_topic.alerts.arn
}

# output "dashboard_name" {
#   description = "CloudWatch Dashboard Name"
#   value       = aws_cloudwatch_dashboard.main.dashboard_name
# }

# ==========================================
# WAF (APPLICATION FIREWALL)
# ==========================================
output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN protecting the ALB"
  value       = aws_wafv2_web_acl.main.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

# --- Private Subnet Outputs ---
output "private_subnet_a_id" {
  description = "The ID of the first private subnet"
  value       = aws_subnet.Privatesubnet_a.id
}

output "private_subnet_b_id" {
  description = "The ID of the second private subnet"
  value       = aws_subnet.Privatesubnet_b.id
}

# --- Public Subnet Outputs ---
output "public_subnet_id" {
  description = "The ID of the first public subnet"
  value       = aws_subnet.Publicsubnet.id
}

output "public_subnet_b_id" {
  description = "The ID of the second public subnet"
  value       = aws_subnet.Publicsubnet_b.id
}

# --- NACL Outputs (Useful for verification) ---
output "private_nacl_id" {
  value = aws_network_acl.PrivateSubnetNACL.id
}

output "public_nacl_id" {
  value = aws_network_acl.PublicSubnetNACL.id
}
