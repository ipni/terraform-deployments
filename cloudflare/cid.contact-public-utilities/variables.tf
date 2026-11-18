variable "cid_contact_addresses" {
  description = <<-EOT
    IPv4 addresses of the zone's A records, as { "<hostname>" = ["<address>", ...] }:
    one entry per hostname in local.a_records (dns.tf), with as many addresses
    as its `count`. Kept out of the repo so the origins stay private: CI sets
    TF_VAR_cid_contact_addresses from the CID_CONTACT_ADDRESSES secret.
  EOT
  type        = map(list(string))
  sensitive   = true
}
