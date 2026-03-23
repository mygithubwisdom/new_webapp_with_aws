resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.Publicsubnet.id,
    aws_subnet.Publicsubnet_b.id
  ]

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = var.node_app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-webapp.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  
  # Even with SSM, keeping the key_name for emergency access via serial console
  key_name      = var.key_pair_name

  # Attach the IAM Instance Profile for SSM Session Manager
  iam_instance_profile {
    name = aws_iam_instance_profile.app_server_profile.name
  }

  # Using my consolidated app_server security group (no port 22 needed!)
  vpc_security_group_ids = [aws_security_group.app_server.id]

  # This is where my Node.js startup script lives
  user_data = base64encode(local.user_data)

  # Enforce IMDSv2 for security (Best Practice)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/sda1" # Ubuntu default is usually /dev/sda1

    ebs {
      volume_size = 8
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-app-instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.Privatesubnet.id, aws_subnet.Privatesubnet_b.id]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

resource "aws_db_subnet_group" "app" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.Privatesubnet.id, aws_subnet.Privatesubnet_b.id]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main-webapp.id

  # Allow DB access from app servers only
  ingress {
    description     = "DB access from app servers"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_server.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main-webapp.cidr_block]
  }

  tags = {
    Name        = "${var.project_name}-db-sg"
    Environment = var.environment
  }
}

# Use AWS default PostgreSQL version for this region (avoids "Cannot find version" errors)
data "aws_rds_engine_version" "postgres" {
  engine       = var.db_engine
  default_only = true
}

resource "aws_db_instance" "db" {
  identifier              = "${var.project_name}-db"
  allocated_storage       = var.db_allocated_storage
  engine                  = var.db_engine
  engine_version          = data.aws_rds_engine_version.postgres.version
  instance_class          = var.db_instance_class
  db_subnet_group_name    = aws_db_subnet_group.app.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = var.db_port
  multi_az                = var.db_multi_az
  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true
  publicly_accessible     = false

  # ... other settings
  storage_encrypted       = true
  kms_key_id              = var.rds_kms_key_arn # Use a Customer Managed Key for Production

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
  }
}

