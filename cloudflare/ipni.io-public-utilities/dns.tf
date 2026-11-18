# Every DNS record of ipni.io, mirrored from the zone in Alex@ipfs.io's Account
# (where the monitoring records are managed by ../ipni.io and the rest by
# hand). Until the registrar transfer, a change to a record there must be made
# here too.

locals {
  # Which hostnames exist and how they are served is public; their addresses
  # come from var.ipni_io_addresses. `count` is how many A records the name has.
  a_records = {
    "ipni.io"                     = { proxied = true }
    "www.ipni.io"                 = { proxied = true }
    "pin.ipni.io"                 = { proxied = false, count = 3 }
    "drand.ipni.io"               = { proxied = false, ttl = 300 }
    "route-chic-1.ipni.io"        = { proxied = true }
    "route-lith-1.ipni.io"        = { proxied = true }
    "route-sing-1.ipni.io"        = { proxied = true }
    "route-chic-1-origin.ipni.io" = { proxied = false }
    "route-lith-1-origin.ipni.io" = { proxied = false }
    "route-sing-1-origin.ipni.io" = { proxied = false }
    "chic-1.bootstrap.ipni.io"    = { proxied = false }
    "chic-1-b.bootstrap.ipni.io"  = { proxied = false }
    "lith-1.bootstrap.ipni.io"    = { proxied = false }
    "sing-1.bootstrap.ipni.io"    = { proxied = false }

    # IPNI monitoring hub on lith-1 (github.com/ipni/infra, docs/03-monitoring.md).
    # Traefik serves the proxied ones on 8443, see the Origin Rule in rules.tf.
    "monitoring.ipni.io"        = { proxied = true, what = "IPNI monitoring, lith-1: Grafana" }
    "argocd.ipni.io"            = { proxied = true, what = "IPNI monitoring, lith-1: Argo CD" }
    "ingest.monitoring.ipni.io" = { proxied = false, what = "IPNI monitoring, lith-1: ingest" }
  }

  # One instance per address, keyed "<hostname>#<n>".
  a_record_instances = merge([
    for name, r in local.a_records : {
      for i in range(try(r.count, 1)) : "${name}#${i}" => {
        name    = name
        index   = i
        count   = try(r.count, 1)
        proxied = r.proxied
        ttl     = try(r.ttl, 1) # 1 = automatic
        comment = try("${r.what}. ${local.managed_by}", local.managed_by)
      }
    }
  ]...)

  # libp2p bootstrap peers (dnsaddr), public by design.
  txt_records = {
    "_dnsaddr.bootstrap.ipni.io" = [
      "dnsaddr=/dnsaddr/chic-1.bootstrap.ipni.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa",
      "dnsaddr=/dnsaddr/chic-1-b.bootstrap.ipni.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN",
      "dnsaddr=/dnsaddr/lith-1.bootstrap.ipni.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb",
      "dnsaddr=/dnsaddr/sing-1.bootstrap.ipni.io/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt",
    ]
    "_dnsaddr.chic-1.bootstrap.ipni.io" = [
      "dnsaddr=/dns4/chic-1.bootstrap.ipni.io/tcp/4001/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa",
      "dnsaddr=/dns4/chic-1.bootstrap.ipni.io/udp/4001/quic-v1/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa",
      "dnsaddr=/dns4/chic-1.bootstrap.ipni.io/tcp/4443/wss/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa",
    ]
    "_dnsaddr.chic-1-b.bootstrap.ipni.io" = [
      "dnsaddr=/dns4/chic-1-b.bootstrap.ipni.io/tcp/4011/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN",
      "dnsaddr=/dns4/chic-1-b.bootstrap.ipni.io/udp/4011/quic-v1/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN",
      "dnsaddr=/dns4/chic-1-b.bootstrap.ipni.io/tcp/4453/wss/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN",
    ]
    "_dnsaddr.lith-1.bootstrap.ipni.io" = [
      "dnsaddr=/dns4/lith-1.bootstrap.ipni.io/tcp/4001/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb",
      "dnsaddr=/dns4/lith-1.bootstrap.ipni.io/udp/4001/quic-v1/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb",
      "dnsaddr=/dns4/lith-1.bootstrap.ipni.io/tcp/4443/wss/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb",
    ]
    "_dnsaddr.sing-1.bootstrap.ipni.io" = [
      "dnsaddr=/dns4/sing-1.bootstrap.ipni.io/tcp/4001/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt",
      "dnsaddr=/dns4/sing-1.bootstrap.ipni.io/udp/4001/quic-v1/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt",
      "dnsaddr=/dns4/sing-1.bootstrap.ipni.io/tcp/4443/wss/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt",
    ]
  }

  txt_record_instances = merge([
    for name, values in local.txt_records : {
      for i, value in values : "${name}#${i}" => { name = name, value = value }
    }
  ]...)
}

resource "cloudflare_dns_record" "a" {
  for_each = local.a_record_instances

  zone_id = local.zone_id
  name    = each.value.name
  type    = "A"
  content = var.ipni_io_addresses[each.value.name][each.value.index]
  proxied = each.value.proxied
  ttl     = each.value.ttl
  comment = each.value.comment

  lifecycle {
    precondition {
      # The secret must list exactly `count` addresses for this hostname.
      condition     = nonsensitive(length(lookup(var.ipni_io_addresses, each.value.name, []))) == each.value.count
      error_message = "IPNI_IO_ADDRESSES must have ${each.value.count} address(es) for ${each.value.name}."
    }
    precondition {
      # Cloudflare rejects comments over 100 characters on the Free plan, and
      # only at apply time.
      condition     = length(each.value.comment) <= 100
      error_message = "The comment for ${each.value.name} is ${length(each.value.comment)} characters; Cloudflare allows 100."
    }
  }
}

resource "cloudflare_dns_record" "txt" {
  for_each = local.txt_record_instances

  zone_id = local.zone_id
  name    = each.value.name
  type    = "TXT"
  # Stored quoted, as in the old zone.
  content = "\"${each.value.value}\""
  ttl     = 1
  comment = local.managed_by
}

# The cidstats Pages project: the old project's until the cutover, then the
# one in this account (pages.tf).
resource "cloudflare_dns_record" "cidstats" {
  zone_id = local.zone_id
  name    = "cidstats.ipni.io"
  type    = "CNAME"
  content = local.cidstats_cutover ? cloudflare_pages_project.cidstats.subdomain : "cidstats.pages.dev"
  proxied = true
  ttl     = 1
  comment = local.managed_by

  # Add the custom domain to the new project before sending traffic to it.
  depends_on = [cloudflare_pages_domain.cidstats]
}

# A hostname in the secret that has no record here would be silently ignored.
check "addresses_match_records" {
  assert {
    condition     = length(setsubtract(nonsensitive(keys(var.ipni_io_addresses)), keys(local.a_records))) == 0
    error_message = "IPNI_IO_ADDRESSES has hostnames with no A record in dns.tf: ${join(", ", setsubtract(nonsensitive(keys(var.ipni_io_addresses)), keys(local.a_records)))}."
  }
}
