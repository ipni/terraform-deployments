# Account-level load balancer pools and monitors used by the Service Worker
# Gateway zones (inbrowser.link, inbrowser.dev). The zone stacks read the pool
# IDs from this stack's outputs.
#
# The Rainbow pools and their monitor are shared with ipfs.io, dweb.link,
# trustless-gateway.link and others: changes here affect all of them.

locals {
  # Cloudflare account "IPFS Public Utilities" (shared with other IPFS services).
  account_id = "0b45911a8258997976f8efdec3ec84c1"
}

# --- Monitors ---

resource "cloudflare_load_balancer_monitor" "rainbow" {
  account_id       = local.account_id
  description      = "Rainbow HTTP monitor"
  type             = "https"
  method           = "GET"
  path             = "/version"
  port             = 443
  expected_codes   = "200"
  expected_body    = "Client: rainbow"
  interval         = 60
  timeout          = 7
  retries          = 5
  consecutive_up   = 2
  consecutive_down = 2
  follow_redirects = false
  allow_insecure   = false
  header = {
    Host = ["trustless-gateway.link"]
  }
}

resource "cloudflare_load_balancer_monitor" "pages_production" {
  account_id       = local.account_id
  description      = "pages-prod"
  type             = "https"
  method           = "GET"
  path             = "/"
  port             = 443
  expected_codes   = "200"
  interval         = 60
  timeout          = 5
  retries          = 2
  follow_redirects = false
  allow_insecure   = false
}

resource "cloudflare_load_balancer_monitor" "pages_staging" {
  account_id       = local.account_id
  description      = "pages-staging"
  type             = "https"
  method           = "GET"
  path             = "/"
  port             = 443
  expected_codes   = "200"
  interval         = 60
  timeout          = 5
  retries          = 2
  follow_redirects = false
  allow_insecure   = false
  header = {
    Host = ["staging.ipfs-service-worker-gateway.pages.dev"]
  }
}

# --- Pools ---

resource "cloudflare_load_balancer_pool" "ovh_bhs_rainbow" {
  account_id      = local.account_id
  name            = "ovh-bhs-rainbow"
  description     = "OVH Beauharnois, QC, Canada"
  enabled         = true
  minimum_origins = 1
  monitor         = cloudflare_load_balancer_monitor.rainbow.id
  check_regions   = ["ENAM"]
  latitude        = 45.309067
  longitude       = -73.89379

  origin_steering = {
    policy = "least_outstanding_requests"
  }
  notification_filter = {
    pool = {}
  }

  origins = [for name, address in var.rainbow_origins.bhs : {
    name          = name
    address       = address
    enabled       = true
    weight        = 1
    flatten_cname = true
  }]
}

resource "cloudflare_load_balancer_pool" "ovh_eri_rainbow" {
  account_id      = local.account_id
  name            = "ovh-eri-rainbow"
  description     = "OVH Erith, UK"
  enabled         = true
  minimum_origins = 1
  monitor         = cloudflare_load_balancer_monitor.rainbow.id
  check_regions   = ["WEU"]
  latitude        = 51.492073
  longitude       = 0.1658941

  origin_steering = {
    policy = "least_outstanding_requests"
  }
  notification_filter = {
    pool = {}
  }

  origins = [for name, address in var.rainbow_origins.eri : {
    name          = name
    address       = address
    enabled       = true
    weight        = 1
    flatten_cname = true
  }]
}

resource "cloudflare_load_balancer_pool" "pages_production" {
  account_id      = local.account_id
  name            = "pages-production"
  enabled         = true
  minimum_origins = 1
  monitor         = cloudflare_load_balancer_monitor.pages_production.id
  check_regions   = ["ALL_REGIONS"]

  notification_filter = {
    pool = {}
  }

  origins = [{
    name          = "production"
    address       = "ipfs-service-worker-gateway.pages.dev"
    enabled       = true
    weight        = 1
    flatten_cname = true
    header = {
      host = ["ipfs-service-worker-gateway.pages.dev"]
    }
  }]
}

resource "cloudflare_load_balancer_pool" "pages_staging" {
  account_id      = local.account_id
  name            = "pages-staging"
  enabled         = true
  minimum_origins = 1
  monitor         = cloudflare_load_balancer_monitor.pages_staging.id
  check_regions   = ["ALL_REGIONS"]

  notification_filter = {
    pool = {}
  }

  origins = [{
    name          = "staging"
    address       = "staging.ipfs-service-worker-gateway.pages.dev"
    enabled       = true
    weight        = 1
    flatten_cname = true
    header = {
      host = ["staging.ipfs-service-worker-gateway.pages.dev"]
    }
  }]
}
