terraform {
  backend "s3" {

    bucket  = "terraform-diag-state"
    key     = "state/terraform.tfstate"
    region  = "us-west-2"
    profile = "diag"
  }
}
