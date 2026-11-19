output "zone_id" {
  description = "ID of the ipni.io zone in IPFS Public Utilities."
  value       = cloudflare_zone.ipni_io.id
}

output "status" {
  description = "Zone status: active since ipni.io moved to this account."
  value       = cloudflare_zone.ipni_io.status
}

output "cidstats_subdomain" {
  description = "pages.dev hostname of the cidstats project in this account, the target of cidstats.ipni.io."
  value       = cloudflare_pages_project.cidstats.subdomain
}

output "name_servers" {
  description = "Nameservers Cloudflare assigned to the zone in this account."
  value       = cloudflare_zone.ipni_io.name_servers
}
