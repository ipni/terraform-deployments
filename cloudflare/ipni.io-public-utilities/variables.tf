variable "ipni_io_addresses" {
  description = <<-EOT
    IPv4 addresses of the zone's A records, as { "<hostname>" = ["<address>", ...] }:
    one entry per hostname in local.a_records (dns.tf), with as many addresses
    as its `count`. Kept out of the repo so the origins behind Cloudflare stay
    private: CI sets TF_VAR_ipni_io_addresses from the IPNI_IO_ADDRESSES secret.
  EOT
  type        = map(list(string))
  sensitive   = true
}

variable "ipni_io_aop_client_key" {
  description = "PEM private key of origin-pull-client.crt (zone-level Authenticated Origin Pulls). From the IPNI_IO_AOP_CLIENT_KEY secret; locally from a git-ignored secrets.auto.tfvars."
  type        = string
  sensitive   = true

  # A missing GitHub secret arrives as an empty string, which would plan fine
  # and only fail at apply.
  validation {
    condition     = can(regex("-----BEGIN [A-Z ]*PRIVATE KEY-----", var.ipni_io_aop_client_key))
    error_message = "ipni_io_aop_client_key is not a PEM private key: set the IPNI_IO_AOP_CLIENT_KEY secret (cloudflare/README.md, repository settings)."
  }
}
