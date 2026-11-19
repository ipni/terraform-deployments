# Zone-level Authenticated Origin Pulls: Cloudflare presents a client
# certificate (mTLS) on every connection it makes to an origin for this zone.
# The certificate is our own, not Cloudflare's shared global AOP one that any
# Cloudflare customer can present, so an origin that requires it only takes
# requests that came through ipni.io and its rules and settings.
#
# Required by Traefik on lith-1 for the proxied monitoring hostnames
# (local.monitoring_hosts in rules.tf: monitoring.ipni.io and argocd.ipni.io;
# github.com/ipni/infra, kubernetes/manifests/eu/lith1/monitoring). Without it
# any Cloudflare account could proxy its own hostname to lith-1:8443 with
# Host: argocd.ipni.io, since the firewall there has to allow all of
# Cloudflare's ranges. Every other origin in the zone (route-origin's Envoy,
# the apex, the ipni-cidstats Pages project) asks for no client certificate and
# never sees it.
#
# origin-pull-client.crt is a copy of certs/origin-pull-client.crt in
# github.com/ipni/workers, signed by certs/origin-pull-ca.crt there; Traefik
# trusts that CA. Both are public. The client key is in that repo's Ansible
# vault (vault_origin_pull_client_key) and reaches this stack as the
# IPNI_IO_AOP_CLIENT_KEY repository secret, which the workflow passes to this
# stack only. The provider has no write-only key attribute, so the key
# is also in this stack's S3 state: anyone who can read that state can get past
# Traefik's certificate check.
#
# Upload no certificate from that CA to any other zone: Traefik would take that
# zone's traffic too.

resource "cloudflare_authenticated_origin_pulls_certificate" "zone" {
  zone_id     = local.zone_id
  certificate = file("${path.module}/origin-pull-client.crt")
  private_key = var.ipni_io_aop_client_key

  lifecycle {
    # A new certificate replaces this one. Upload it before deleting the old
    # one: with neither, Cloudflare presents nothing and Traefik refuses
    # Grafana and Argo CD (Cloudflare error 525). The zone uses the most
    # recently uploaded certificate.
    create_before_destroy = true
  }
}

resource "cloudflare_authenticated_origin_pulls_settings" "zone" {
  zone_id = local.zone_id
  enabled = true

  depends_on = [cloudflare_authenticated_origin_pulls_certificate.zone]
}

# Cloudflare keeps presenting an expired certificate, which Traefik refuses.
# Warns on every plan from 60 days before; renew in ipni/workers (README,
# "Authenticated Origin Pulls") and replace origin-pull-client.crt and the
# secret here.
check "aop_certificate_expiry" {
  assert {
    condition     = timecmp(cloudflare_authenticated_origin_pulls_certificate.zone.expires_on, timeadd(plantimestamp(), "1440h")) > 0
    error_message = "The zone-level AOP certificate expires on ${cloudflare_authenticated_origin_pulls_certificate.zone.expires_on}. Renew it before then, or Grafana and Argo CD go dark behind Cloudflare."
  }
}
