locals {
  # Cloudflare account "IPFS Public Utilities" (shared with other IPFS services).
  account_id = "0b45911a8258997976f8efdec3ec84c1"
  zone_id    = "920073f8f22220ca3a3c514d81195e35" # inbrowser.dev

  # Load balancer pool IDs, managed in ../load-balancing.
  pools = data.terraform_remote_state.load_balancing.outputs.pool_ids

  # Managed in ../inbrowser.link/pages.tf.
  pages_project = "ipfs-service-worker-gateway"
}

data "terraform_remote_state" "load_balancing" {
  backend = "s3"
  config = {
    bucket = "ipni-terraform-state"
    key    = "cloudflare/load-balancing/terraform.tfstate"
    region = "us-east-2"
  }
}
