# Routing key for grafana.ipni.io's PagerDuty contact point. Read it with
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

# For the Cloudflare PagerDuty destination, connected to this service.
output "swg_service_id" {
  value = pagerduty_service.swg.id
}
