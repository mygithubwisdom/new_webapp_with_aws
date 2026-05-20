terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # Using a recent version
    }
  }
  required_version = ">= 1.4"
}

provider "aws" {
  region = var.aws_region
}


# VPC & GATEWAYS
# ==========================================

resource "aws_vpc" "main-webapp" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main-webapp.id
  tags   = { Name = "${var.project_name}-igw" }
}


# SUBNETS
# Public Subnets (For ALB and NAT Gateway)

resource "aws_subnet" "Publicsubnet" {
  vpc_id                  = aws_vpc.main-webapp.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = { Name = "${var.project_name}-public-subnet-a" }
}

resource "aws_subnet" "Publicsubnet_b" {
  vpc_id                  = aws_vpc.main-webapp.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = { Name = "${var.project_name}-public-subnet-b" }
}

# Private Subnets (For App Servers and RDS)
resource "aws_subnet" "Privatesubnet_a" {
  vpc_id            = aws_vpc.main-webapp.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = var.availability_zones[0]
  tags              = { Name = "${var.project_name}-private-subnet-a" }
}

resource "aws_subnet" "Privatesubnet_b" {
  vpc_id            = aws_vpc.main-webapp.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = var.availability_zones[1]
  tags              = { Name = "${var.project_name}-private-subnet-b" }
}

# ==========================================
# ROUTING
# ==========================================

# Public Routing
resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.main-webapp.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "PublicSubnetAssociation" {
  subnet_id      = aws_subnet.Publicsubnet.id
  route_table_id = aws_route_table.publicroutetable.id
}

resource "aws_route_table_association" "PublicSubnetBAssociation" {
  subnet_id      = aws_subnet.Publicsubnet_b.id
  route_table_id = aws_route_table.publicroutetable.id
}

# Private Routing (NAT Gateway)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.Publicsubnet.id
  tags          = { Name = "${var.project_name}-nat-gateway" }
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.main-webapp.id
  tags   = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route" "private_to_internet_via_nat" {
  route_table_id         = aws_route_table.PrivateRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "PrivateSubnetAssociation" {
  subnet_id      = aws_subnet.Privatesubnet_a.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

resource "aws_route_table_association" "PrivateSubnetBAssociation" {
  subnet_id      = aws_subnet.Privatesubnet_b.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
