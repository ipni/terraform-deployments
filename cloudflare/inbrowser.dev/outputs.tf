output "health_check_id" {
  description = "Read by ../notifications."
  value       = module.zone.health_check_id
}
