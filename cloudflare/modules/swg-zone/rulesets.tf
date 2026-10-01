# Zone entry-point rulesets. Cloudflare-managed rulesets (OWASP, DDoS, ...)
# are owned by Cloudflare and not managed here.

locals {
  docs_url = "https://docs.ipfs.tech/how-to/replace-public-gateways-with-self-hosted-ipfs/"
}

resource "cloudflare_ruleset" "rate_limit" {
  zone_id = var.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_ratelimit"
  rules = [{
    description = "global rate limit (${local.managed_by})"
    enabled     = true
    expression  = "(http.host wildcard r\"*.${var.zone_name}\" and not starts_with(http.request.uri.path, \"/ipfs-sw-\"))"
    action      = "block"
    action_parameters = {
      response = {
        status_code  = 429
        content_type = "text/plain"
        content      = "${var.rate_limit.message}\n${local.docs_url}"
      }
    }
    ratelimit = {
      characteristics     = ["cf.unique_visitor_id", "cf.colo.id"]
      period              = var.rate_limit.period
      requests_per_period = var.rate_limit.requests_per_period
      mitigation_timeout  = var.rate_limit.mitigation_timeout
    }
  }]
}

resource "cloudflare_ruleset" "firewall_custom" {
  zone_id = var.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_request_firewall_custom"
  rules = [{
    description = "not a browser (${local.managed_by})"
    enabled     = true
    expression  = "(not starts_with(http.user_agent, \"Mozilla\"))"
    action      = "block"
    action_parameters = {
      response = {
        status_code  = 403
        content_type = "text/plain"
        content      = "403 Forbidden\n${local.docs_url}"
      }
    }
  }]
}

resource "cloudflare_ruleset" "response_headers" {
  zone_id = var.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_response_headers_transform"
  rules = [{
    description = "X-Robots-Tag: noindex, nofollow (${local.managed_by})"
    enabled     = true
    expression  = coalesce(var.noindex_expression, "(ends_with(http.host, \".ipfs.${var.zone_name}\")) or (ends_with(http.host, \".ipns.${var.zone_name}\")) or (starts_with(http.request.uri.path, \"/ipfs/\")) or (starts_with(http.request.uri.path, \"/ipns/\"))")
    action      = "rewrite"
    action_parameters = {
      headers = {
        X-Robots-Tag = {
          operation = "set"
          value     = "noindex, nofollow"
        }
      }
    }
  }]
}

resource "cloudflare_ruleset" "url_normalization" {
  zone_id     = var.zone_id
  kind        = "zone"
  name        = "Entrypoint for url normalization ruleset"
  description = "ruleset for controlling url normalization"
  phase       = "http_request_sanitize"
  rules = [{
    enabled    = true
    expression = "true"
    action     = "execute"
    action_parameters = {
      id      = "70339d97bdb34195bbf054b1ebe81f76" # Cloudflare Normalization Ruleset
      version = "latest"
      overrides = {
        rules = [
          { id = "78723a9e0c7c4c6dbec5684cb766231d", enabled = false },
          { id = "b232b534beea4e00a21dcbb7a8a545e9", enabled = true },
          { id = "20e18610e4a048d6b87430b3cb2d89a3", enabled = false },
          { id = "60444c0705d4438799584a15cca2cb7d", enabled = false },
        ]
      }
    }
  }]
}

resource "cloudflare_ruleset" "cache_settings" {
  zone_id = var.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_request_cache_settings"
  rules   = length(var.cache_rules) > 0 ? var.cache_rules : null
}
