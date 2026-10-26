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

# Routing key for Healthchecks on sing1 (ipni/infra): the webhook of its
# lith1-alertmanager check.
output "needle_healthchecks_integration_key" {
  value     = pagerduty_service_integration.needle_healthchecks.integration_key
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
