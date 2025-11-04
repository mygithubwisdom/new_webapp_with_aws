variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "Terraform AWS webapp-Setup"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "main-webapp"
}
variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}
variable "key_pair_name" {
  description = "Name of the SSH key pair for EC2 instance"
  type        = string
  default     = "aliciakeysserver"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "Development"
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
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

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
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

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
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

variable "ssh_port" {
  description = "SSH port number"
  type        = number
  default     = 22
}

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

variable "SSH_laptop_ip" {
  description = "SSH for my laptop's public IP address with CIDR suffix "
  type        = string
  default     = "0.0.0.0/32"
}

variable "your_laptop_ip" {
  description = "The public IP address of your laptop in CIDR notation "
  type        = string // (e.g., 203.0.113.5/32)
}
