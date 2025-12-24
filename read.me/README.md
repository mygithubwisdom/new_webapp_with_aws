# AWS Web Application - Infrastructure as Code & CI/CD

A production-ready Node.js web application deployed on AWS using Terraform for Infrastructure as Code and GitHub Actions for CI/CD automation. This project demonstrates best practices for cloud infrastructure provisioning, automated deployments, and monitoring.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture Diagram](#architecture-diagram)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Application Deployment](#application-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Logging](#monitoring--logging)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

## 🎯 Project Overview

This project implements a complete AWS infrastructure setup for a Node.js/Express.js web application with the following components:

- **Infrastructure as Code**: Terraform configuration for provisioning AWS resources
- **Network Architecture**: VPC with public and private subnets
- **Compute**: EC2 instance running Ubuntu 22.04
- **Storage**: S3 bucket for static content
- **Security**: Security groups and Network ACLs
- **Monitoring**: CloudWatch integration for logs and metrics
- **CI/CD**: GitHub Actions pipeline for automated testing and deployment

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Internet Gateway                             │
└──────────────────────────────┬──────────────────────────────────────┘
                                │
                                │
        ┌───────────────────────┴───────────────────────┐
        │                                                 │
        │              VPC (10.0.0.0/16)                 │
        │                                                 │
        │  ┌──────────────────────────────────────────┐  │
        │  │     Public Subnet (10.0.1.0/24)         │  │
        │  │                                          │  │
        │  │  ┌──────────────────────────────────┐   │  │
        │  │  │   EC2 Instance (t3.micro)        │   │  │
        │  │  │   Ubuntu 22.04                    │   │  │
        │  │  │   ┌──────────────────────────┐   │   │  │
        │  │  │   │  Node.js App (Port ***) │   │   │  │
        │  │  │   │  PM2 Process Manager     │   │   │  │
        │  │  │   │  CloudWatch Agent        │   │   │  │
        │  │  │   └──────────────────────────┘   │   │  │
        │  │  │                                  │   │  │
        │  │  │   Security Group:                │   │  │
        │  │  │   - SSH (**)                     │   │  │
        │  │  │   - HTTP (**)                    │   │  │
        │  │  │   - HTTPS (**)                  │   │  │
        │  │  │   - Node.js App (***)           │   │  │
        │  │  └──────────────────────────────────┘   │  │
        │  │                                          │  │
        │  │   Route Table: **/0 → IGW          │  │
        │  └──────────────────────────────────────────┘  │
        │                                                 │
        │  ┌──────────────────────────────────────────┐  │
        │  │    Private Subnet (10.0.2.0/24)          │  │
        │  │    (Reserved for future use)             │  │
        │  │                                          │  │
        │  │   Route Table: Local only                │  │
        │  └──────────────────────────────────────────┘  │
        │                                                 │
        └─────────────────────────────────────────────────┘
                                │
                                │
        ┌───────────────────────┴───────────────────────┐
        │                                                 │
        │              AWS Services                       │
        │                                                 │
        │  ┌──────────────────────────────────────────┐  │
        │  │  S3 Bucket                               │  │
        │  │  - Static Content Storage                │  │
        │  │  - Versioning Enabled                    │  │
        │  │  - Encryption (AES256)                   │  │
        │  │  - Private Access                        │  │
        │  └──────────────────────────────────────────┘  │
        │                                                 │
        │  ┌──────────────────────────────────────────┐  │
        │  │  CloudWatch                              │  │
        │  │  - Log Groups                            │  │
        │  │  - Metrics Collection                    │  │
        │  │  - EC2 Monitoring                        │  │
        │  └──────────────────────────────────────────┘  │
        │                                                 │
        └─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD Pipeline                    │
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │   Push to    │───▶│   Run Tests  │───▶│   Deploy to  │         │
│  │   Branch     │    │   (Jest)     │    │   EC2        │         │
│  └──────────────┘    └──────────────┘    └──────────────┘         │
│         │                   │                      │                │
│         │                   │                      │                │
│         ▼                   ▼                      ▼                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │  All Branches│    │  Test Report │    │  SSH to EC2   │         │
│  │              │    │  Coverage    │    │  PM2 Restart  │         │
│  └──────────────┘    └──────────────┘    └──────────────┘         │
│                                                                    │
└─────────────────────────────────────────────────────────────────────┘
```

## 📦 Prerequisites

Before you begin, ensure you have the following installed and configured:

### Required Software

1. **Terraform** (>= 1.4)
   ```bash
   # Download from https://www.terraform.io/downloads
   # Or use package manager:
   # Windows: choco install terraform
   # macOS: brew install terraform
   # Linux: Download from HashiCorp website
   ```

2. **AWS CLI** (>= 2.0)
   ```bash
   # Download from https://aws.amazon.com/cli/
   # Verify installation:
   aws --version
   ```

3. **Node.js** (>= 18.x)
   ```bash
   # Download from https://nodejs.org/
   # Verify installation:
   node --version
   npm --version
   ```

4. **Git**
   ```bash
   # Download from https://git-scm.com/
   git --version
   ```

### AWS Account Setup

1. **AWS Account**: Create an AWS account if you don't have one
2. **IAM User**: Create an IAM user with programmatic access
3. **AWS Credentials**: Configure AWS credentials:
   ```bash
   aws configure
   # Enter your Access Key ID
   # Enter your Secret Access Key
   # Enter default region (e.g., us-east-1)
   # Enter default output format (json)
   ```

4. **EC2 Key Pair**: Create an EC2 key pair in your AWS region:
   ```bash
   # Via AWS Console:
   # EC2 → Key Pairs → Create Key Pair
   # Name: myssh (or your preferred name)
   # Save the .pem file securely
   
   # Or via AWS CLI:
   aws ec2 create-key-pair --key-name (keyname) --query 'KeyMaterial' --output text > keyname.pem
   chmod 400 ***.pem  # Linux/Mac
   ```

5. **Get Your Public IP**: Find your public IP address:
   ```bash
   # Linux/Mac:
   curl ifconfig.me
   
   # Windows PowerShell:
   (Invoke-WebRequest -Uri "https://ifconfig.me").Content
   ```

## 🚀 Setup Instructions

### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd new_webapp_with_aws #local repo folder
```

### Step 2: Configure Terraform Variables

Create a `terraform.tfvars` file in the `terraform/` directory:

```bash
cd terraform
```

Create `terraform.tfvars`: # optional

```hcl
# AWS Configuration
aws_region = "var.yourchoice"
project_name = "Terraform AWS webapp-Setup"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
availability_zones = ["yourchoice"]

# EC2 Configuration
key_pair_name = "var.keypair_name"  # Your EC2 key pair name
ec2_instance_type = "t3.micro"

# Security Configuration
SSH_laptop_ip = "YOUR_PUBLIC_IP/32"  # e.g., "203.0.113.45/32" # best practice
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"

# Environment
environment = "Development"
```

**Important**: Replace `YOUR_PUBLIC_IP` with your actual public IP address in CIDR notation (e.g., `203.0.113.45/32`).

### Step 3: Initialize Terraform

```bash
cd terraform
terraform init
```

This will:
- Download the AWS provider plugin
- Initialize the backend (S3 bucket for state storage)

### Step 4: Review Terraform Plan

```bash
terraform plan
```

Review the planned changes to ensure everything looks correct.

### Step 5: Apply Terraform Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will create:
- VPC with public and private subnets
- Internet Gateway
- Route tables
- Security groups
- EC2 instance
- S3 bucket
- CloudWatch log groups

**Note**: The EC2 instance will automatically install Node.js, PM2, and CloudWatch agent via user data script.

### Step 6: Get EC2 Instance Information

After Terraform completes, get the EC2 public IP:

```bash
terraform output public_ip
```

Save this IP address for deployment.

### Step 7: Test SSH Connection 

## change directory to ~/.ssh for ubuntu/linux/git bash 
 cd ~/.ssh # save SSH_PRIVATE_KEY inside .ssh folder for permission 

```bash
# Replace with your key path and public IP
ssh -i ~/.ssh/***.pem ubuntu@<EC2_PUBLIC_IP>
```

If successful, you should be connected to the EC2 instance.

## 🏗️ Infrastructure Deployment

### Terraform Configuration Files

The infrastructure is defined in the `terraform/` directory:

- **`main.tf`**: VPC, subnets, internet gateway, route tables, EC2 instance
- **`security-groups.tf`**: Security groups and Network ACLs
- **`s3.tf`**: S3 bucket configuration
- **`cloudwatch.tf`**: CloudWatch log groups and metrics
- **`ec2.tf`**: EC2 user data script and IAM policies
- **`variable.tf`**: Variable definitions
- **`output.tf`**: Output values
- **`backend.tf`**: Terraform state backend configuration
- **`provider.tf`**: AWS provider configuration

### Key Infrastructure Components

#### VPC and Networking
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24 (EC2 instance)
- **Private Subnet**: ***/24 (reserved for future use)
- **Internet Gateway**: Enables internet access for public subnet

#### Security Groups
- **EC2 Security Group**: Allows SSH (*), HTTP (*), HTTPS (*), and Node.js app (*)
- **Network ACLs**: Additional layer of network security

#### EC2 Instance
- **AMI**: Ubuntu 22.04 LTS
- **Instance Type**: t3.micro (free tier eligible)
- **User Data**: Automatically installs:
  - Node.js 18.x
  - PM2 process manager
  - CloudWatch agent

#### S3 Bucket
- **Purpose**: Static content storage
- **Features**:
  - Versioning enabled
  - Server-side encryption (AES256)
  - Private access (no public access)

## 📱 Application Deployment

### Manual Deployment

#### Option 1: Using the Deployment Script

```bash
cd terraform/scripts
chmod +x deploy.sh

# Deploy to EC2
./deploy.sh <EC2_PUBLIC_IP> ~/.ssh/***.pem
```

#### Option 2: Manual Deployment Steps

1. **Copy application files to EC2**:
   ```bash
   cd terraform/app
   scp -i ~/.ssh/**** \
       index.js package.json package-lock.json \
       ubuntu@<EC2_PUBLIC_IP>:/home/ubuntu/app/
   ```

2. **SSH into EC2 and install dependencies**:
   ```bash
   ssh -i ~/.ssh/**** ubuntu@<EC2_PUBLIC_IP>
   cd /home/ubuntu/app
   npm install --production
   ```

3. **Start the application with PM2**:
   ```bash
   pm2 start index.js --name node-app
   pm2 save
   pm2 startup  # Enable PM2 to start on system boot
   ```

4. **Verify the application**:
   ```bash
   # From your local machine
   curl http://<EC2_PUBLIC_IP>:***
   curl http://<EC2_PUBLIC_IP>:***/health
   ```

### Application Endpoints

- **Root**: `http://<EC2_PUBLIC_IP>:3000/`
- **Health Check**: `http://<EC2_PUBLIC_IP>:3000/health`
- **API Info**: `http://<EC2_PUBLIC_IP>:3000/api/info`

## 🔄 CI/CD Pipeline

### GitHub Actions Setup

1. **Create GitHub Actions Workflow**

   
       
      

2. **Configure GitHub Secrets**

   Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `EC2_SSH_KEY`: Contents of your EC2 private key (.pem file)

3. **Pipeline Behavior**

   - **On every push**: Runs tests
   - **On push to main**: Runs tests + deploys to EC2
   - **On pull requests**: Runs tests only

## 📊 Monitoring & Logging

### CloudWatch Integration

The EC2 instance is configured to send logs to CloudWatch:

1. **View Logs**:
   - AWS Console → CloudWatch → Log groups
   - Log group: `/aws/ec2/*****`
   - Log stream: `{instance_id}`

2. **View Metrics**:
   - AWS Console → CloudWatch → Metrics
   - EC2 namespace → Per-instance metrics
   - Monitor: CPU utilization, network in/out, disk I/O

3. **Application Logs**:
   - Application logs are written to `/home/ubuntu/app/app.log`
   - CloudWatch agent automatically forwards these logs

### PM2 Monitoring

SSH into EC2 and use PM2 commands:

```bash
pm2 list          # List all processes
pm2 logs node-app # View application logs
pm2 monit         # Real-time monitoring
pm2 status        # Process status
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

**Issue**: `Error: creating EC2 Instance: InvalidKeyPair.NotFound`

**Solution**: Ensure the key pair name in `terraform.tfvars` matches an existing key pair in your AWS region.

#### 2. Cannot SSH to EC2

**Issue**: Connection timeout or permission denied

**Solutions**:
- Verify security group allows SSH from your IP
- Check that your public IP is correct in `terraform.tfvars`
- Ensure key file permissions: `chmod 400 ****.pem`
- Verify EC2 instance is running: `aws ec2 describe-instances`

#### 3. Application Not Accessible

**Issue**: Cannot access application on port 3000

**Solutions**:
- Verify security group allows port 3000
- Check if application is running: `pm2 list`
- View application logs: `pm2 logs node-app`
- Check EC2 instance status in AWS Console

#### 4. CloudWatch Logs Not Appearing

**Issue**: No logs in CloudWatch

**Solutions**:
- Verify CloudWatch agent is running: `sudo systemctl status amazon-cloudwatch-agent`
- Check agent configuration: `/opt/aws/amazon-cloudwatch-agent/etc/config.json`
- Restart agent: `sudo systemctl restart amazon-cloudwatch-agent`

#### 5. GitHub Actions Deployment Fails

**Issue**: SSH connection fails in GitHub Actions

**Solutions**:
- Verify `EC2_SSH_KEY` secret contains the full private key (including headers)
- Check that EC2 security group allows SSH from GitHub Actions IPs
- Verify EC2 instance is running and accessible

### Useful Commands

```bash
# Terraform
terraform plan          # Preview changes
terraform apply         # Apply changes
terraform destroy       # Destroy infrastructure
terraform output        # View outputs
terraform state list    # List resources

# AWS CLI
aws ec2 describe-instances --filters "Name=tag:Name,Values=HelloWorld"
aws s3 ls
aws logs describe-log-groups

# Application
curl http://<EC2_IP>:*/health
ssh -i ~/.ssh/***.pem ubuntu@<EC2_IP>
```

## 📁 Project Structure

```
new_webapp_with_aws/
├── read.me/
│   └── README.md          # This file
├── terraform/
│   ├── app/               # Node.js application
│   │   ├── index.js       # Main application file
│   │   ├── package.json   # Dependencies
│   │   ├── tests/         # Test files
│   │   └── coverage/      # Test coverage reports
│   ├── scripts/
│   │   └── deploy.sh      # Deployment script
│   ├── main.tf            # VPC, subnets, EC2
│   ├── ec2.tf             # EC2 user data
│   ├── security-groups.tf # Security groups
│   ├── s3.tf              # S3 bucket
│   ├── cloudwatch.tf      # CloudWatch config
│   ├── variable.tf        # Variables
│   ├── output.tf          # Outputs
│   ├── provider.tf        # Provider config
│   └── backend.tf         # State backend
└── README.md              # Root README
```

## 🔒 Security Best Practices

1. **SSH Access**: Restrict SSH access to your IP only
2. **Security Groups**: Follow principle of least privilege
3. **S3 Bucket**: Keep bucket private, enable encryption
4. **IAM Roles**: Use IAM roles instead of access keys when possible
5. **Secrets Management**: Store sensitive data in GitHub Secrets
6. **Regular Updates**: Keep EC2 instance and dependencies updated
7. **Configure AWS credentials** via  OIDC

## 📝 Notes

- The EC2 instance uses `t3.micro` which is eligible for AWS Free Tier
- S3 bucket name includes a random suffix for uniqueness
- CloudWatch agent is automatically installed and configured
- Application runs on port 3000 (configurable via environment variable)
- PM2 ensures application restarts automatically on failure

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `cd terraform/app && npm test`
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 👤 Author

**Wisdom**

---

**Last Updated**: November 5, 2025

For questions or issues, please open an issue in the repository.

