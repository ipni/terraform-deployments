# Shared state bucket, created by bootstrap/state-backend.
# Until it exists, use `terraform init -backend=false`.
terraform {
  backend "s3" {
    bucket       = "ipni-terraform-state"
    key          = "cloudflare/notifications/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
