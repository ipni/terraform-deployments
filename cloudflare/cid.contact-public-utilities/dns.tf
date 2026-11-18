# Every DNS record of cid.contact, mirrored from the zone in Alex@ipfs.io's
# Account (managed by hand there). Until the nameserver change, a change to a
# record there must be made here too.

locals {
  # Which hostnames exist and how they are served is public; their addresses
  # come from var.cid_contact_addresses. `count` is how many A records the
  # name has.
  a_records = {
    "sf.cid.contact"           = { proxied = false }
    "sf2.cid.contact"          = { proxied = false }
    "chic1.cid.contact"        = { proxied = false }
    "find.chic1.cid.contact"   = { proxied = false }
    "ingest.chic1.cid.contact" = { proxied = false }

    # Copied as is: it points at Cloudflare's own addresses, so it answers
    # 403 and serves nothing today.
    "docs.cid.contact" = { proxied = true, count = 2 }
  }

  # One instance per address, keyed "<hostname>#<n>".
  a_record_instances = merge([
    for name, r in local.a_records : {
      for i in range(try(r.count, 1)) : "${name}#${i}" => {
        name    = name
        index   = i
        count   = try(r.count, 1)
        proxied = r.proxied
      }
    }
  ]...)

  cname_records = {
    # The indexer behind CloudFront, DNS-only: moving it behind Cloudflare is
    # a separate project.
    "cid.contact" = { content = "d3gfvti28lf5wu.cloudfront.net", proxied = false }

    # ACM validation for CloudFront's certificates: without them, they stop
    # renewing.
    "_69b92f021d1ba8e399b622325428fb6e.cid.contact"       = { content = "_67b73443075f75f6b366696071ca675b.rdvkfhcmrm.acm-validations.aws", proxied = false }
    "_2947e0b9a12a35a0f920f673c31f02f6.infra.cid.contact" = { content = "_79e66e6fcb4fc98c9a19231c1ef3d455.rdvkfhcmrm.acm-validations.aws", proxied = false }

    "find.sf.cid.contact"    = { content = "sf.cid.contact", proxied = false }
    "ingest.sf.cid.contact"  = { content = "sf.cid.contact", proxied = false }
    "find.sf2.cid.contact"   = { content = "sf2.cid.contact", proxied = false }
    "ingest.sf2.cid.contact" = { content = "sf2.cid.contact", proxied = false }

    "status.cid.contact"   = { content = "stats.uptimerobot.com", proxied = false }
    "web-ipni.cid.contact" = { content = "ipni.github.io", proxied = true }
  }

  # prod.cid.contact is delegated to Route 53.
  ns_records = {
    "prod.cid.contact" = [
      "ns-412.awsdns-51.com",
      "ns-1765.awsdns-28.co.uk",
      "ns-678.awsdns-20.net",
      "ns-1230.awsdns-25.org",
    ]
  }

  ns_record_instances = merge([
    for name, values in local.ns_records : {
      for i, value in values : "${name}#${i}" => { name = name, value = value }
    }
  ]...)
}

resource "cloudflare_dns_record" "a" {
  for_each = local.a_record_instances

  zone_id = local.zone_id
  name    = each.value.name
  type    = "A"
  content = var.cid_contact_addresses[each.value.name][each.value.index]
  proxied = each.value.proxied
  ttl     = 1 # automatic
  comment = local.managed_by

  lifecycle {
    precondition {
      # The secret must list exactly `count` addresses for this hostname.
      condition     = nonsensitive(length(lookup(var.cid_contact_addresses, each.value.name, []))) == each.value.count
      error_message = "CID_CONTACT_ADDRESSES must have ${each.value.count} address(es) for ${each.value.name}."
    }
  }
}

resource "cloudflare_dns_record" "cname" {
  for_each = local.cname_records

  zone_id = local.zone_id
  name    = each.key
  type    = "CNAME"
  content = each.value.content
  proxied = each.value.proxied
  ttl     = 1
  comment = local.managed_by
}

resource "cloudflare_dns_record" "ns" {
  for_each = local.ns_record_instances

  zone_id = local.zone_id
  name    = each.value.name
  type    = "NS"
  content = each.value.value
  ttl     = 1
  comment = local.managed_by
}

# The filecoin-redirect Pages project in this account (pages.tf). The old
# zone points at the old project's filecoin-redirect.pages.dev; this one at
# the new project, which only matters once this zone is live.
resource "cloudflare_dns_record" "filecoin_redirect" {
  for_each = toset(["direct.cid.contact", "fetch.cid.contact"])

  zone_id = local.zone_id
  name    = each.key
  type    = "CNAME"
  content = cloudflare_pages_project.filecoin_redirect.subdomain
  proxied = true
  ttl     = 1
  comment = local.managed_by
}

# A hostname in the secret that has no record here would be silently ignored.
check "addresses_match_records" {
  assert {
    condition     = length(setsubtract(nonsensitive(keys(var.cid_contact_addresses)), keys(local.a_records))) == 0
    error_message = "CID_CONTACT_ADDRESSES has hostnames with no A record in dns.tf: ${join(", ", setsubtract(nonsensitive(keys(var.cid_contact_addresses)), keys(local.a_records)))}."
  }
}
