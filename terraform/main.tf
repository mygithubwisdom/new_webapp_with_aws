terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.4"
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Optional: Configure S3 backend for state management
# backend "s3" {
#   bucket = "your-terraform-state-bucket"
#   key    = "node-app/terraform.tfstate"
#   region = "us-east-1"
# }


# VPC
resource "aws_vpc" "main-webapp" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main-webapp.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


# Subnets
resource "aws_subnet" "Publicsubnet" {
  vpc_id                  = aws_vpc.main-webapp.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = "${var.project_name}-public-subnet"
  }

}
resource "aws_subnet" "Privatesubnet" {
  vpc_id            = aws_vpc.main-webapp.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zones[0]

  tags = {

    Name = "${var.project_name}-private-subnet"
  }
}

resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.main-webapp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate the Public Route Table with the Public Subnet
resource "aws_route_table_association" "PublicSubnetAssociation" {
  subnet_id      = aws_subnet.Publicsubnet.id
  route_table_id = aws_route_table.publicroutetable.id
}

# Elastic IP for NAT Gateway (for private subnet internet access)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.Publicsubnet.id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}
# Private Route Table
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.main-webapp.id

  # No direct route to the internet
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate the Private Route Table with the Private Subnet
resource "aws_route_table_association" "PrivateSubnetAssociation" {
  subnet_id      = aws_subnet.Privatesubnet.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}






