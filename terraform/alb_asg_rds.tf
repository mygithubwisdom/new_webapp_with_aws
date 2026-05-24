resource "aws_lb" "main" {
  name               = "${var.project_name}-alb" #3
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.Publicsubnet.id,
    aws_subnet.Publicsubnet_b.id
  ]

  enable_deletion_protection = false
  enable_http2               = true

  # # DISABLED access_logs temporarily
  #   access_logs {
  #     bucket  = aws_s3_bucket.alb_logs.id
  #     enabled = true
  #   }

  # depends_on = [
  #   aws_s3_bucket_policy.alb_logs
  # ]

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  # Even with SSM, keeping the key_name for emergency access via serial console
  key_name = var.key_pair_name

  # Attach the IAM Instance Profile for SSM Session Manager
  iam_instance_profile {
    name = aws_iam_instance_profile.app_server_profile.name
  }

  # Using my consolidated app_server security group (no port 22 needed!)
  vpc_security_group_ids = [aws_security_group.app_server.id]

  # This is where my Node.js startup script lives
  user_data = filebase64("${path.module}/deploy.sh")

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

resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg" #4
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-webapp.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health" # ← Must exist in your app
    protocol            = "HTTP"
    matcher             = "200" # ← Your app must return 200
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.Privatesubnet_a.id, aws_subnet.Privatesubnet_b.id]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.main.arn]

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
  subnet_ids = [aws_subnet.Privatesubnet_a.id, aws_subnet.Privatesubnet_b.id]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
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
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
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
  storage_encrypted = true
  kms_key_id        = var.rds_kms_key_arn # Use a Customer Managed Key for Production

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
  }
}
