# Routing key for the hub's Alertmanager (ipni/infra SOPS:
# alertmanager-secrets -> pagerduty-indexers-routing-key). Read it with
# `terraform output -raw indexers_integration_key`; never print it in CI.
output "indexers_integration_key" {
  value     = pagerduty_service_integration.indexers_events.integration_key
  sensitive = true
}

# Routing key for the hub's Alertmanager (ipni/infra SOPS:
# alertmanager-secrets -> pagerduty-routing-key).
output "needle_integration_key" {
  value     = pagerduty_service_integration.needle_events.integration_key
  sensitive = true
}

# Routing key for the hub's Alertmanager, box-level alerts (ipni/infra SOPS:
# alertmanager-secrets -> pagerduty-infra-routing-key).
output "infra_integration_key" {
  value     = pagerduty_service_integration.infra_events.integration_key
  sensitive = true
}

# Routing keys for the dead-man's switches (ipni/infra docs/03-monitoring.md,
# Healthchecks): the webhook of each one's lith1-alertmanager check.
output "infra_healthchecks_integration_key" {
  value     = pagerduty_service_integration.infra_healthchecks.integration_key
  sensitive = true
}

output "infra_heartbeat_integration_key" {
  value     = pagerduty_service_integration.infra_heartbeat.integration_key
  sensitive = true
}

# Routing keys for the hub's Alertmanager (ipni/infra SOPS:
# alertmanager-secrets -> pagerduty-<service>-routing-key).
output "bootstrap_integration_key" {
  value     = pagerduty_service_integration.bootstrap_events.integration_key
  sensitive = true
}

output "content_integration_key" {
  value     = pagerduty_service_integration.content_events.integration_key
  sensitive = true
}

output "route_origin_integration_key" {
  value     = pagerduty_service_integration.route_origin_events.integration_key
  sensitive = true
}

# For the Cloudflare PagerDuty destination, connected to this service.
output "swg_service_id" {
  value = pagerduty_service.swg.id
}
