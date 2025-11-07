# NETWORK OUTPUTS

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main-webapp.id
}

output "public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.example.public_ip
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.static_content.id
}