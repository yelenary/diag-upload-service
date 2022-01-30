# Setup the AWS provider
terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  profile                 = "diag"
  region                  = "us-west-2"
}
