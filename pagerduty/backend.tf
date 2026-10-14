# Shared state bucket, created by bootstrap/state-backend. The CI roles reach
# the pagerduty/ prefix through bootstrap/github-actions.
terraform {
  backend "s3" {
    bucket       = "ipni-terraform-state"
    key          = "pagerduty/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
