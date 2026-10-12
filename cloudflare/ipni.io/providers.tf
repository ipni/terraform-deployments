# Authenticates with the CLOUDFLARE_API_TOKEN environment variable. ipni.io is
# in a different Cloudflare account from the other stacks, so CI sets it from
# the CLOUDFLARE_IPNI_IO_API_TOKEN(_READ) secrets for this stack.
provider "cloudflare" {}
