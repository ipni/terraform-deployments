# Production Service Worker Gateway.
module "zone" {
  source = "../modules/swg-zone"

  account_id    = local.account_id
  zone_id       = local.zone_id
  zone_name     = "inbrowser.link"
  pages_project = cloudflare_pages_project.service_worker_gateway.name
  pages_target  = "ipfs-service-worker-gateway.pages.dev"

  dnslink_build_cid = {
    cid     = "bafybeicdizrjewbd4yd6ca45oan525nws7fpqwlty2suhxl6msfqpr3rjy"
    comment = "ipfs-shipyard/helia-service-worker-gateway/2b90273cd70f242917695a70ab57fb99ef1a1996"
  }

  # IPFS gateway-checker test CID.
  health_check_cid = "bafybeifx7yeb55armcsxwwitkymga5xf53dxiarykms3ygqic223w5sk3m"

  # Pages first, Rainbow as failover.
  load_balancers = {
    ipfs = {
      pools    = [local.pools.pages_production, local.pools.ovh_eri_rainbow, local.pools.ovh_bhs_rainbow]
      fallback = local.pools.ovh_bhs_rainbow
    }
    ipns = {
      pools    = [local.pools.pages_production, local.pools.ovh_bhs_rainbow, local.pools.ovh_eri_rainbow]
      fallback = local.pools.ovh_bhs_rainbow
    }
  }

  rate_limit = {
    requests_per_period = 50
    period              = 10
    mitigation_timeout  = 10
    message             = "Too Many Requests from your IP"
  }

  extra_zone_settings = {
    sort_query_string_for_cache = "on"
  }
}
