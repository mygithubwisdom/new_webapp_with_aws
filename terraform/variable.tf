# PROJECT & REGION
# ==========================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-aws-webapp-setup"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

# ==========================================
# COMPUTE (EC2 & ASG)

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name (Kept as backup/emergency access)"
  type        = string
  default     = "ubuntutask"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# ==========================================
# NETWORKING (VPC & SUBNETS)

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "main-webapp"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "map_public_ip_on_launch" {
  description = "Whether to map public IP on launch for public subnet"
  type        = bool
  default     = true
}

# ==========================================
# PORTS & SECURITY CONFIG

variable "node_app_port" {
  description = "Node.js application port number"
  type        = number
  default     = 3000
}

variable "http_port" {
  description = "HTTP port number"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "HTTPS port number"
  type        = number
  default     = 443
}

variable "public_nacl_name" {
  description = "Name for the public subnet NACL"
  type        = string
  default     = "PublicSubnetNACL"
}

variable "private_nacl_name" {
  description = "Name for the private subnet NACL"
  type        = string
  default     = "PrivateSubnetNACL"
}

# ==========================================
# DATABASE (RDS)

variable "db_engine" {
  description = "Database engine for RDS"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16.1"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# ==========================================
# MONITORING & COMPLIANCE

variable "notification_email" {
  description = "Email address for SNS notifications"
  type        = string
  default     = ""
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC flow logs"
  type        = number
  default     = 30
}

variable "cpu_low_threshold" {
  description = "CPU utilization threshold for low CPU alarm"
  type        = number
  default     = 20
}

variable "cpu_high_threshold" {
  description = "CPU utilization threshold for high CPU alarm"
  type        = number
  default     = 80
}

variable "iam_users_require_mfa" {
  description = "List of IAM users that require MFA"
  type        = list(string)
  default     = []
}

# ==========================================
# WAF & SECURITY SERVICES

variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["RU", "CN", "IR", "KP"]
}

variable "waf_rate_limit" {
  description = "Rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "rds_kms_key_arn" {
  description = "KMS Key ARN for RDS encryption"
  type        = string
  default     = ""
}