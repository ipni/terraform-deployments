data "terraform_remote_state" "load_balancing" {
  backend = "s3"
  config = {
    bucket = "ipni-terraform-state"
    key    = "cloudflare/load-balancing/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "zone" {
  for_each = toset(["inbrowser.link", "inbrowser.dev"])

  backend = "s3"
  config = {
    bucket = "ipni-terraform-state"
    key    = "cloudflare/${each.key}/terraform.tfstate"
    region = "us-east-2"
  }
}
