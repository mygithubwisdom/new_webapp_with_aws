# resource "aws_eip" "web_server_eip" {
#   domain   = "vpc"
#   instance = aws_instance.example.id
# }

resource "aws_iam_policy" "s3_access" {
  name = "AllowS3TerraformBackendAccess"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::terraform-aws-webapp-setup-static-content-4ec3ab3c",
          "arn:aws:s3:::terraform-aws-webapp-setup-static-content-4ec3ab3c/*"
        ]
      },
      {
        Sid    = "EC2DescribeAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}
