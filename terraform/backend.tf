terraform {
  backend "s3" {
    bucket  = "terraform-aws-webapp-prod-state-1669w"
    key     = "terraform/state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-prod-state-lock"
  }
}