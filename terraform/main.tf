# Prerequisites:
# A terraform state bucket with the name "blackstack-terraform-state"

terraform {
  backend "s3" {
    bucket = "blackstack-terraform-state"
    key    = "lambda_qwen"
    region = "eu-west-2"
  }
}

locals {
  namespace = "lambda_qwen"
}
