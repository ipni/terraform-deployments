# Cache Rules for the CDN hostnames. Rules merge in order and later matches
# override earlier ones, so the default bypass comes first. They match only
# cdn_hosts (rules.tf).
#
# Every eligible rule keys on the resolved host (so all CDN hostnames share
# one cache), never on User-Agent or device type, and ignores the browser's
# Origin header (the origin always answers Access-Control-Allow-Origin: *).
# 5xx are never stored.

locals {
  # The API answers JSON or NDJSON depending on Accept.
  cache_accept = ["application/json", "application/x-ndjson"]
}

resource "cloudflare_ruleset" "cache" {
  zone_id = local.zone_id
  kind    = "zone"
  name    = "default"
  phase   = "http_request_cache_settings"
  rules = [
    {
      description = "Default: bypass (${local.managed_by})"
      enabled     = true
      expression  = local.cdn_hosts_expr
      action      = "set_cache_settings"
      action_parameters = {
        cache = false
      }
    },
    {
      description = "/cid and /multihash (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (starts_with(http.request.uri.path, \"/cid/\") or starts_with(http.request.uri.path, \"/multihash/\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        cache_key = {
          cache_by_device_type       = false
          cache_deception_armor      = false
          ignore_query_strings_order = true
          custom_key = {
            host         = { resolved = true }
            query_string = { include = { list = ["cascade"] } }
            header = {
              exclude_origin = true
              contains       = { accept = local.cache_accept }
            }
          }
        }
        edge_ttl = {
          mode    = "override_origin"
          default = 7200
          status_code_ttl = [
            { status_code = 404, value = local.negative_ttl },
            { status_code_range = { from = 500, to = 599 }, value = -1 },
          ]
        }
        browser_ttl = { mode = "respect_origin" }
      }
    },
    {
      description = "/routing/v1 (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (starts_with(http.request.uri.path, \"/routing/v1/\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        cache_key = {
          cache_by_device_type       = false
          cache_deception_armor      = false
          ignore_query_strings_order = true
          custom_key = {
            host         = { resolved = true }
            query_string = { include = { list = ["filter-protocols", "filter-addrs"] } }
            header = {
              exclude_origin = true
              contains       = { accept = local.cache_accept }
            }
          }
        }
        edge_ttl = {
          mode = "respect_origin"
          status_code_ttl = [
            { status_code = 404, value = local.negative_ttl },
            { status_code_range = { from = 500, to = 599 }, value = -1 },
          ]
        }
        browser_ttl = { mode = "respect_origin" }
      }
    },
    {
      description = "/ipni/v0/sample (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (starts_with(http.request.uri.path, \"/ipni/v0/sample/\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        cache_key = {
          cache_by_device_type       = false
          cache_deception_armor      = false
          ignore_query_strings_order = true
          custom_key = {
            host         = { resolved = true }
            query_string = { include = { list = ["beacon", "federation_epoch", "max"] } }
            header       = { exclude_origin = true }
          }
        }
        edge_ttl = {
          mode    = "override_origin"
          default = 7200
          status_code_ttl = [
            { status_code = 404, value = local.negative_ttl },
            { status_code_range = { from = 500, to = 599 }, value = -1 },
          ]
        }
        browser_ttl = { mode = "respect_origin" }
      }
    },
    {
      description = "/providers (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (http.request.uri.path eq \"/providers\" or starts_with(http.request.uri.path, \"/providers/\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        cache_key = {
          cache_by_device_type       = false
          cache_deception_armor      = false
          ignore_query_strings_order = true
          custom_key = {
            host         = { resolved = true }
            query_string = { exclude = { all = true } }
            header       = { exclude_origin = true }
          }
        }
        edge_ttl = {
          mode    = "override_origin"
          default = 300
          status_code_ttl = [
            { status_code = 404, value = local.negative_ttl },
            { status_code_range = { from = 500, to = 599 }, value = -1 },
          ]
        }
        browser_ttl = { mode = "respect_origin" }
      }
    },
    {
      description = "/carmirror (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (starts_with(http.request.uri.path, \"/carmirror\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        cache_key = {
          cache_by_device_type       = false
          cache_deception_armor      = false
          ignore_query_strings_order = true
          custom_key = {
            host         = { resolved = true }
            query_string = { include = { list = ["list", "path", "recursive"] } }
            header       = { exclude_origin = true }
          }
        }
        edge_ttl = {
          mode    = "override_origin"
          default = 7200
          status_code_ttl = [
            { status_code = 404, value = local.negative_ttl },
            { status_code_range = { from = 500, to = 599 }, value = -1 },
          ]
        }
        browser_ttl = { mode = "respect_origin" }
      }
    },
    {
      description = "/metering/providers (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (http.request.uri.path eq \"/metering/providers\")"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        cache_key = {
          cache_by_device_type       = false
          cache_deception_armor      = false
          ignore_query_strings_order = true
          custom_key = {
            host         = { resolved = true }
            query_string = { exclude = { all = true } }
            header       = { exclude_origin = true }
          }
        }
        edge_ttl = {
          mode    = "override_origin"
          default = 300
          status_code_ttl = [
            { status_code_range = { from = 500, to = 599 }, value = -1 },
          ]
        }
        browser_ttl = { mode = "respect_origin" }
      }
    },
    {
      description = "/sync/status: bypass (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (starts_with(http.request.uri.path, \"/sync/status\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = false
      }
    },
    {
      description = "Ingest and announce: bypass (${local.managed_by})"
      enabled     = true
      expression  = "${local.cdn_hosts_expr} and (starts_with(http.request.uri.path, \"/ingest/\") or http.request.uri.path eq \"/announce\")"
      action      = "set_cache_settings"
      action_parameters = {
        cache = false
      }
    },
  ]
}
