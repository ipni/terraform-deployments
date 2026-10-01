# Cloudflare Notifications for the Service Worker Gateway
# (inbrowser.link, inbrowser.dev).

locals {
  # Cloudflare account "IPFS Public Utilities" (shared with other IPFS services).
  account_id = "0b45911a8258997976f8efdec3ec84c1"

  # UUID of the ipfs-service-worker-gateway Pages project (managed in
  # ../inbrowser.link/pages.tf). The provider only exposes the name as its id.
  pages_project_uuid = "dc709c2c-4327-4c7c-8588-be09c3dde4de"

  zone_ids = [
    "3cf6893c26dde38efa39910a57798a59", # inbrowser.link
    "920073f8f22220ca3a3c514d81195e35", # inbrowser.dev
  ]

  mechanisms = {
    email    = [for e in var.alert_emails : { id = e }]
    webhooks = [for w in cloudflare_notification_policy_webhooks.slack : { id = w.id }]
  }
}

resource "cloudflare_notification_policy_webhooks" "slack" {
  count = var.slack_webhook_url == "" ? 0 : 1

  account_id = local.account_id
  name       = "slack-swg-alerts"
  url        = var.slack_webhook_url
}

# A Rainbow or Pages pool, or one of its origins, changes health.
resource "cloudflare_notification_policy" "load_balancing_health" {
  account_id  = local.account_id
  name        = "SWG load balancer pool health"
  description = "Pools behind *.ipfs / *.ipns on inbrowser.link and inbrowser.dev"
  alert_type  = "load_balancing_health_alert"
  enabled     = true

  filters = {
    pool_id      = values(data.terraform_remote_state.load_balancing.outputs.pool_ids)
    event_source = ["pool", "origin"]
    new_health   = ["Unhealthy", "Healthy"]
  }

  mechanisms = local.mechanisms
}

# A Pages deployment of the gateway fails (production or staging).
resource "cloudflare_notification_policy" "pages_deployment_failed" {
  account_id  = local.account_id
  name        = "SWG Pages deployment failed"
  description = "ipfs-service-worker-gateway Pages project"
  alert_type  = "pages_event_alert"
  enabled     = true

  filters = {
    project_id  = [local.pages_project_uuid]
    environment = ["ENVIRONMENT_PRODUCTION", "ENVIRONMENT_PREVIEW"]
    event       = ["EVENT_DEPLOYMENT_FAILED"]
  }

  mechanisms = local.mechanisms
}

# Origin 5xx error rate on either zone drops availability below the SLO.
resource "cloudflare_notification_policy" "origin_error_rate" {
  account_id  = local.account_id
  name        = "SWG origin 5xx error rate"
  description = "inbrowser.link and inbrowser.dev"
  alert_type  = "http_alert_origin_error"
  enabled     = true

  filters = {
    zones = local.zone_ids
    slo   = ["99.5"]
  }

  mechanisms = local.mechanisms
}

# Unusual spike or drop in traffic on either zone.
resource "cloudflare_notification_policy" "traffic_anomalies" {
  account_id  = local.account_id
  name        = "SWG traffic anomalies"
  description = "inbrowser.link and inbrowser.dev"
  alert_type  = "traffic_anomalies_alert"
  enabled     = true

  filters = {
    zones                     = local.zone_ids
    alert_trigger_preferences = ["zscore_spike_and_drop"]
  }

  mechanisms = local.mechanisms
}
