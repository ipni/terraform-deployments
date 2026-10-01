resource "cloudflare_dns_record" "apex" {
  zone_id = var.zone_id
  name    = var.zone_name
  type    = "CNAME"
  content = var.pages_target
  proxied = true
  ttl     = 1
  settings = {
    flatten_cname = false
  }
}

# The domain sends no email: null MX, SPF -all, empty DKIM, DMARC reject.
resource "cloudflare_dns_record" "mx_null" {
  zone_id  = var.zone_id
  name     = var.zone_name
  type     = "MX"
  content  = "."
  priority = 0
  ttl      = 1
  comment  = var.no_email_comments.mx
}

resource "cloudflare_dns_record" "spf" {
  zone_id = var.zone_id
  name    = var.zone_name
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1
  comment = var.no_email_comments.spf
}

resource "cloudflare_dns_record" "dkim" {
  zone_id = var.zone_id
  name    = "*._domainkey.${var.zone_name}"
  type    = "TXT"
  content = "v=DKIM1; p="
  ttl     = 1
  comment = var.no_email_comments.dkim
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc.${var.zone_name}"
  type    = "TXT"
  content = "v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s"
  ttl     = 1
  comment = var.no_email_comments.dmarc
}

resource "cloudflare_dns_record" "dnslink_build_cid" {
  zone_id = var.zone_id
  name    = "_dnslink.build-cid.${var.zone_name}"
  type    = "TXT"
  content = "dnslink=/ipfs/${var.dnslink_build_cid.cid}"
  ttl     = 1
  comment = var.dnslink_build_cid.comment
}

# Proof of ownership for the Public Suffix List entry.
resource "cloudflare_dns_record" "psl" {
  zone_id = var.zone_id
  name    = "_psl.${var.zone_name}"
  type    = "TXT"
  content = "\"https://github.com/publicsuffix/list/pull/2413\""
  ttl     = 1
}
