# Only settings changed from Cloudflare's defaults are managed.
locals {
  zone_settings = merge({
    always_use_https    = "on"
    brotli              = "on"
    cache_level         = "simplified"
    http3               = "on"
    ipv6                = "on"
    prefetch_preload    = "on"
    replace_insecure_js = "off"
    ssl                 = "strict"
  }, var.extra_zone_settings)
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.zone_settings

  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}

# Numeric, so kept out of the string map above.
resource "cloudflare_zone_setting" "browser_cache_ttl" {
  zone_id    = var.zone_id
  setting_id = "browser_cache_ttl"
  value      = 0 # respect origin headers
}

resource "cloudflare_tiered_cache" "this" {
  zone_id = var.zone_id
  value   = "on"
}

resource "cloudflare_zone_dnssec" "this" {
  zone_id = var.zone_id
  status  = "active"
}
