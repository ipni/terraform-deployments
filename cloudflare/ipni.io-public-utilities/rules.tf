# The zone's Origin and Configuration Rules, mirrored from ../ipni.io.

locals {
  # Proxied monitoring hostnames: Cloudflare sends them to Traefik on 8443.
  monitoring_hosts = join(" ", [
    for name in sort(keys(local.a_records)) : "\"${name}\""
    if startswith(try(local.a_records[name].what, ""), "IPNI monitoring") && local.a_records[name].proxied
  ])

  route_hosts = join(" ", [
    for name in ["route-sing-1.ipni.io", "route-chic-1.ipni.io", "route-lith-1.ipni.io"] : "\"${name}\""
  ])
}

# Port 443 on lith-1 is taken (route-origin's Envoy), so the proxied
# monitoring hostnames go to 8443.
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
# their origins have real certificates.
resource "cloudflare_ruleset" "config_settings" {
  zone_id = local.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_config_settings"
  rules = [
    {
      description = "Route origins -> full strict (${local.managed_by})"
      enabled     = true
      expression  = "(http.host in {${local.route_hosts}})"
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
