# The ipni.io zone: only what this repo manages in it. Everything else in the
# zone (route-*, *.bootstrap, pin, ...) is still managed by hand, see
# github.com/ipni/workers.
#
# Today: the IPNI monitoring hub on lith-1 (github.com/ipni/infra,
# docs/03-monitoring.md).
#   monitoring.ipni.io         Grafana, through Cloudflare's proxy
#   argocd.ipni.io             Argo CD, through Cloudflare's proxy
#   ingest.monitoring.ipni.io  metrics and logs from the other boxes, DNS only:
#                              Alloy connects to lith-1 directly
# Traefik on lith-1 serves all three on port 8443 (443 there is route-origin's
# Envoy), with a Let's Encrypt certificate from cert-manager.

locals {
  # Zone ipni.io, in the Cloudflare account "Alex@ipfs.io's Account", not
  # "IPFS Public Utilities" like the other stacks.
  zone_id = "fd0f396d7ce348e1fb7a5ebc6438c55f"

  lith1 = "46.166.169.131"

  managed_by = "Managed by Terraform: github.com/ipni/terraform-deployments"

  monitoring_records = {
    "monitoring.ipni.io"        = { proxied = true, what = "Grafana" }
    "argocd.ipni.io"            = { proxied = true, what = "Argo CD" }
    "ingest.monitoring.ipni.io" = { proxied = false, what = "metrics and logs ingest, reached directly" }
  }

  # The proxied ones: Cloudflare sends them to Traefik on 8443, verified.
  monitoring_proxied = sort([for name, r in local.monitoring_records : name if r.proxied])
  monitoring_hosts   = join(" ", [for name in local.monitoring_proxied : "\"${name}\""])
}

resource "cloudflare_dns_record" "monitoring" {
  for_each = local.monitoring_records

  zone_id = local.zone_id
  name    = each.key
  type    = "A"
  content = local.lith1
  proxied = each.value.proxied
  ttl     = 1 # automatic
  comment = "IPNI monitoring on lith-1: ${each.value.what}. ${local.managed_by}"
}

# Port 443 on lith-1 is taken, so the proxied hostnames go to 8443. The zone
# had no Origin Rules before this; any new one belongs here.
resource "cloudflare_ruleset" "origin" {
  zone_id = local.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_request_origin"
  rules = [{
    description = "IPNI monitoring to Traefik on 8443 (${local.managed_by})"
    enabled     = true
    expression  = "(http.host in {${local.monitoring_hosts}})"
    action      = "route"
    action_parameters = {
      origin = { port = 8443 }
    }
  }]
}

# The zone's SSL mode is Full; these hostnames get Full (strict), because
# their origins have real certificates. The first rule was made by hand for
# github.com/ipni/workers' route-origin and is kept exactly as it was: this
# ruleset holds every Configuration Rule of the zone, so it is managed here
# whole, imported below.
import {
  to = cloudflare_ruleset.config_settings
  id = "zones/fd0f396d7ce348e1fb7a5ebc6438c55f/ad950764ab904309bd34ad91c81af455"
}

resource "cloudflare_ruleset" "config_settings" {
  zone_id = local.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_config_settings"
  rules = [
    {
      ref         = "edf5d720050f496e85b6d0f32e53e9db"
      description = "Route origins -> full strict"
      enabled     = true
      expression  = "(http.host in {\"route-sing-1.ipni.io\" \"route-chic-1.ipni.io\" \"route-lith-1.ipni.io\"})"
      action      = "set_config"
      action_parameters = {
        ssl = "strict"
      }
    },
    {
      description = "IPNI monitoring -> full strict (${local.managed_by})"
      enabled     = true
      expression  = "(http.host in {${local.monitoring_hosts}})"
      action      = "set_config"
      action_parameters = {
        ssl = "strict"
      }
    },
  ]
}
