output "health_check_id" {
  value = cloudflare_healthcheck.subdomain_gateway.id
}

output "badbits_health_check_id" {
  description = "ID of the badbits sync health check, or null when the zone doesn't have one."
  value       = one(cloudflare_healthcheck.badbits_sync[*].id)
}
