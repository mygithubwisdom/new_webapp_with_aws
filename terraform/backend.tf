terraform {
  backend "s3" {
    bucket  = "terraform-aws-webapp-setup-static-content-4ec3ab3c"
    key     = "terraform/state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}