# Shared state bucket, created by bootstrap/state-backend.
terraform {
  backend "s3" {
    bucket       = "ipni-terraform-state"
    key          = "cloudflare/ipni.io-public-utilities/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
