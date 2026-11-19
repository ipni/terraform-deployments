output "zone_id" {
  description = "ID of the cid.contact zone in IPFS Public Utilities."
  value       = cloudflare_zone.cid_contact.id
}

output "status" {
  description = "Zone status: pending until the nameservers at Squarespace point here, then active."
  value       = cloudflare_zone.cid_contact.status
}

output "name_servers" {
  description = "Nameservers Cloudflare assigned to the zone in this account: set them at Squarespace to move cid.contact here."
  value       = cloudflare_zone.cid_contact.name_servers
}

output "filecoin_redirect_subdomain" {
  description = "pages.dev hostname of the filecoin-redirect project in this account, the target of direct. and fetch.cid.contact after the cutover."
  value       = cloudflare_pages_project.filecoin_redirect.subdomain
}

output "certificate_status" {
  description = "Status of the advanced certificate: change the nameservers once it is active."
  value       = cloudflare_certificate_pack.cid_contact.status
}

output "certificate_validation_records" {
  description = "TXT records to add to the cid.contact zone in Alex@ipfs.io's Account, so the certificate is issued before the nameserver change."
  value = [
    for r in coalesce(cloudflare_certificate_pack.cid_contact.validation_records, []) : {
      name  = r.txt_name
      value = r.txt_value
    }
  ]
}
