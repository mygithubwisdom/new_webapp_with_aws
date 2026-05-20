# AWS Systems Manager (SSM) Session Manager Configuration

# IAM Role for EC2 to use SSM
resource "aws_iam_role" "app_server_role" {
  name = "${var.project_name}-app-server-role"

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

  tags = {
    Name = "${var.project_name}-app-server-role"
  }
}

# Custom policy for CloudWatch Logs
resource "aws_iam_role_policy" "ssm_cloudwatch" {
  name = "${var.project_name}-ssm-cloudwatch-policy"
  role = aws_iam_role.app_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::aws-ssm-*/*"
      }
    ]
  })
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "app_server_profile" {
  name = "${var.project_name}-app-server-profile"
  role = aws_iam_role.app_server_role.name

  tags = {
    Name = "${var.project_name}-app-server-profile"
  }
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name

  tags = {
    Name = "${var.project_name}-ssm-profile"
  }
}

# Add this to give your EC2 instances permission to push logs
resource "aws_iam_role_policy_attachment" "ssm_and_logs" {
  role       = aws_iam_role.app_server_role.name # Change to your actual App Role name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# resource "aws_iam_role" "ssm_role" {
#   name = "${var.project_name}-ssm-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#     }]
#   })
# }
