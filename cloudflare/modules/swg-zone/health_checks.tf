# End-to-end probe of the subdomain gateway: DNS, load balancer, Snippets and
# origin. The gateway only serves the Service Worker bootstrap page (the CID is
# fetched in the browser), so this checks the gateway is up, not the content.
resource "cloudflare_healthcheck" "subdomain_gateway" {
  zone_id     = var.zone_id
  name        = "swg-ipfs-subdomain"
  description = "Service Worker Gateway bootstrap on *.ipfs.${var.zone_name}. ${local.managed_by}"
  address     = "${var.health_check_cid}.ipfs.${var.zone_name}"
  type        = "HTTPS"

  check_regions         = ["WNAM", "ENAM", "WEU"]
  interval              = 60
  timeout               = 5
  retries               = 2
  consecutive_fails     = 2
  consecutive_successes = 2

  http_config = {
    method           = "GET"
    path             = "/"
    port             = 443
    expected_codes   = ["200"]
    expected_body    = "IPFS Service Worker Gateway"
    follow_redirects = false
    allow_insecure   = false
    header = {
      # The gateway answers non-browser user agents with 403.
      "User-Agent" = ["Mozilla/5.0 (compatible; Cloudflare-Healthcheck) Chrome/130.0"]
    }
  }
}

# Badbits denylist freshness, answered by the gateway-edge Worker: 200 with
# "fresh":true while its sync ran in the last 2h, 503 otherwise. The edge keeps
# enforcing the last synced list either way, so a stopped sync is otherwise
# silent. The body match keeps a 200 from the installer (no Worker) failing.
resource "cloudflare_healthcheck" "badbits_sync" {
  count = var.badbits_status_check ? 1 : 0

  zone_id     = var.zone_id
  name        = "swg-badbits-sync"
  description = "Badbits denylist sync freshness, from the gateway-edge Worker. ${local.managed_by}"
  address     = "${var.health_check_cid}.ipfs.${var.zone_name}"
  type        = "HTTPS"

  # One region is enough: the answer comes from KV, the same everywhere.
  check_regions         = ["WEU"]
  interval              = 300
  timeout               = 5
  retries               = 2
  consecutive_fails     = 2
  consecutive_successes = 1

  http_config = {
    method           = "GET"
    path             = "/ipfs-sw-badbits-status"
    port             = 443
    expected_codes   = ["200"]
    expected_body    = "\"fresh\":true"
    follow_redirects = false
    allow_insecure   = false
    header = {
      # The gateway answers non-browser user agents with 403.
      "User-Agent" = ["Mozilla/5.0 (compatible; Cloudflare-Healthcheck) Chrome/130.0"]
    }
  }
}
