# An edge certificate issued before the nameserver change. Universal SSL is
# only issued once the zone is active, so without this the proxied hostnames
# (direct., fetch., web-ipni.) would have no certificate for the first minutes
# after the move. The zone is on Enterprise, which includes advanced
# certificates.
#
# While the zone is pending, its TXT validation records go in the cid.contact
# zone in Alex@ipfs.io's Account (by hand: that zone isn't managed here), which
# still answers for the domain. Read them, and the certificate's status, in the
# new zone's dashboard (SSL/TLS > Edge Certificates) or the API, not from
# Terraform: they change after the apply, and CI never applies a refresh. Change
# the nameservers only once the certificate is active. After the move,
# Cloudflare renews it from this zone.
#
# Changing hosts, type, validation method, validity or certificate authority
# replaces the certificate: a new order that needs validating again. Once the
# zone is active, Universal SSL covers the same hostnames meanwhile.
resource "cloudflare_certificate_pack" "cid_contact" {
  zone_id           = local.zone_id
  type              = "advanced"
  hosts             = ["cid.contact", "*.cid.contact"]
  validation_method = "txt"
  validity_days     = 90
  # As the old zone's certificate. cid.contact has no CAA records.
  certificate_authority = "lets_encrypt"
}
