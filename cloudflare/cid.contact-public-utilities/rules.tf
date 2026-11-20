# Origin and Configuration Rules for the CDN hostnames (Phase 2 of the move
# from CloudFront). They match only cdn_hosts, so they do nothing until a
# proxied CDN hostname exists.

locals {
  # Hostnames the CDN config applies to. cid.contact joins at the cutover.
  cdn_hosts      = ["cf-test.cid.contact"]
  cdn_hosts_expr = "(http.host in {${join(" ", [for h in local.cdn_hosts : "\"${h}\""])}})"

  # Where cache misses go. Traefik routes on this Host.
  active_origin = "sf.cid.contact"

  # Edge TTL for 404s: 60 while testing on cf-test; raise before the cutover.
  negative_ttl = 60
}

# Rules merge in order; later matches win.
resource "cloudflare_ruleset" "origin" {
  zone_id = local.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_request_origin"
  rules = [
    {
      description = "CDN -> active origin (${local.managed_by})"
      enabled     = true
      expression  = local.cdn_hosts_expr
      action      = "route"
      action_parameters = {
        # host_header also sets the SNI.
        host_header = local.active_origin
        origin      = { host = local.active_origin }
      }
    },
    {
      # Served only by sf's Traefik (carmirror, metering), whatever the
      # active origin is.
      description = "carmirror and metering stay on sf (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (starts_with(http.request.uri.path, \"/carmirror\") or http.request.uri.path eq \"/metering/providers\")"
      action      = "route"
      action_parameters = {
        host_header = "sf.cid.contact"
        origin      = { host = "sf.cid.contact" }
      }
    },
  ]
}

# The origins have real certificates.
resource "cloudflare_ruleset" "config_settings" {
  zone_id = local.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_config_settings"
  rules = [{
    description = "CDN -> full strict (${local.managed_by})"
    enabled     = true
    expression  = local.cdn_hosts_expr
    action      = "set_config"
    action_parameters = {
      ssl = "strict"
    }
  }]
}
