# An edge certificate issued before the nameserver change. Universal SSL is
# only issued once the zone is active, so without this the proxied hostnames
# (direct., fetch., web-ipni.) would have no certificate for the first minutes
# after the move. The zone is on Enterprise, which includes advanced
# certificates.
#
# While the zone is pending, the TXT records in the output
# `certificate_validation_records` go in the cid.contact zone in
# Alex@ipfs.io's Account (by hand: that zone isn't managed here), which still
# answers for the domain. Change the nameservers only once this certificate is
# active. After the move, Cloudflare renews it from this zone.
resource "cloudflare_certificate_pack" "cid_contact" {
  zone_id           = local.zone_id
  type              = "advanced"
  hosts             = ["cid.contact", "*.cid.contact"]
  validation_method = "txt"
  validity_days     = 90
  # As the old zone's certificate. cid.contact has no CAA records.
  certificate_authority = "lets_encrypt"
}
