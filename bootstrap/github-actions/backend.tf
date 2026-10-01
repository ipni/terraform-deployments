terraform {
  backend "s3" {
    bucket       = "ipni-terraform-state"
    key          = "bootstrap/github-actions/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
