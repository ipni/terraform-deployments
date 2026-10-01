# State backend bootstrap

Creates the shared S3 bucket for Terraform state. Run once, by hand:

```sh
terraform init
terraform apply
```

This stack starts with local state. After the bucket exists, add a `backend "s3"`
block (key `bootstrap/state-backend/terraform.tfstate`) and run
`terraform init -migrate-state` so its own state lives in the bucket too (done:
see `backend.tf`). Terraform 1.16 (required) reads `aws login` sessions
directly.

Every other stack uses:

```hcl
backend "s3" {
  bucket       = "ipni-terraform-state"
  key          = "<path/of/stack>/terraform.tfstate"
  region       = "us-east-2"
  encrypt      = true
  use_lockfile = true
}
```
