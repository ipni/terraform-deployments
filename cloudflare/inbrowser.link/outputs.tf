output "health_check_id" {
  description = "Read by ../notifications."
  value       = module.zone.health_check_id
}

output "badbits_health_check_id" {
  description = "Read by ../notifications."
  value       = module.zone.badbits_health_check_id
}
