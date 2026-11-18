# Only settings changed from Cloudflare's defaults are managed, as in
# modules/swg-zone. These are the two the old zone has changed. The new zone
# already has ipv6 on; replace_insecure_js is off there, so it is the one
# real change.
locals {
  zone_settings = {
    ipv6                = "on"
    replace_insecure_js = "on"
  }
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.zone_settings

  zone_id    = local.zone_id
  setting_id = each.key
  value      = each.value
}
