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
  description = "pages.dev hostname of the filecoin-redirect project in this account (null until the cutover), the target of direct. and fetch.cid.contact."
  value       = one(cloudflare_pages_project.filecoin_redirect[*].subdomain)
}
