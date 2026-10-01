# Staging Service Worker Gateway (deployed from the `staging` branch).
module "zone" {
  source = "../modules/swg-zone"

  account_id    = local.account_id
  zone_id       = local.zone_id
  zone_name     = "inbrowser.dev"
  pages_project = local.pages_project
  pages_target  = "staging.ipfs-service-worker-gateway.pages.dev"

  dnslink_build_cid = {
    cid     = "bafybeidp6kdbis6yc44jtgly62q5tq6rr43kg5qiq2ersvz63xutjeljvm"
    comment = "ipfs-shipyard/service-worker-gateway/796632294a302527e857602eec87135ef1b63c68"
  }

  # IPFS gateway-checker test CID.
  health_check_cid = "bafybeifx7yeb55armcsxwwitkymga5xf53dxiarykms3ygqic223w5sk3m"

  # Pages first, Rainbow as failover.
  load_balancers = {
    ipfs = {
      pools    = [local.pools.pages_staging, local.pools.ovh_bhs_rainbow, local.pools.ovh_eri_rainbow]
      fallback = local.pools.ovh_bhs_rainbow
    }
    ipns = {
      pools    = [local.pools.pages_staging, local.pools.ovh_bhs_rainbow, local.pools.ovh_eri_rainbow]
      fallback = local.pools.ovh_bhs_rainbow
    }
  }

  rate_limit = {
    requests_per_period = 50
    period              = 10
    mitigation_timeout  = 300
    message             = "Too Many Requests from your IP, wait 5m"
  }

  cache_rules = [{
    description = "shared cache for all subdomains and params"
    enabled     = true
    expression  = "(ends_with(http.host, \"inbrowser.dev\"))"
    action      = "set_cache_settings"
    action_parameters = {
      cache = true
      edge_ttl = {
        mode    = "override_origin"
        default = 86400
      }
      browser_ttl = {
        mode    = "override_origin"
        default = 86400
      }
      cache_key = {
        custom_key = {
          header = {
            exclude_origin = true
          }
          host = {
            resolved = true
          }
          query_string = {
            exclude = {
              all = true
            }
          }
        }
      }
    }
  }]

  # Same logic as production, clauses in a different order.
  noindex_expression = "(starts_with(http.request.uri.path, \"/ipfs/\")) or (starts_with(http.request.uri.path, \"/ipns/\")) or (ends_with(http.host, \".ipfs.inbrowser.dev\")) or (ends_with(http.host, \".ipns.inbrowser.dev\"))"

  no_email_comments = {
    mx    = "no email"
    spf   = "no email"
    dmarc = "disbale email"
  }

  extra_zone_settings = {
    proxy_read_timeout = "300"
  }
}
