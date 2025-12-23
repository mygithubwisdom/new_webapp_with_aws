# KMS Key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-s3-kms-key"
    Environment = var.environment
  }
}

# KMS Key Alias for S3
resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# S3 Bucket for static content
resource "aws_s3_bucket" "static_content" {
  bucket = "terraform-aws-webapp-setup-static-content-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-static-bucket"
    Environment = var.environment
  }
}

# S3 Bucket for access logs
resource "aws_s3_bucket" "access_logs" {
  bucket = "terraform-aws-webapp-setup-access-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-access-logs-bucket"
    Environment = var.environment
  }
}

# Block public access for access logs bucket
resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging for static content bucket
resource "aws_s3_bucket_logging" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "static-content-logs/"
}

# Random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Block public access
resource "aws_s3_bucket_public_access_block" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption with customer-managed KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

# Server-side encryption for access logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}
