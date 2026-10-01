# The bucket this stack creates also holds this stack's own state.
# First run starts with local state, then `terraform init -migrate-state`.
terraform {
  backend "s3" {
    bucket       = "ipni-terraform-state"
    key          = "bootstrap/state-backend/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
