# ipni.io in the Cloudflare account "IPFS Public Utilities", moved from
# "Alex@ipfs.io's Account". ipni.io is registered with Cloudflare Registrar, so
# the move was Cloudflare's inter-account registrar transfer. The zone's DNS
# records, rules and settings were mirrored here first, so nothing went missing.
#
# The zone was added by hand in the dashboard and is imported below: the CI
# tokens are scoped to single zones, so they cannot create one.

locals {
  # Cloudflare account "IPFS Public Utilities" (shared with other IPFS services).
  account_id = "0b45911a8258997976f8efdec3ec84c1"
  zone_id    = cloudflare_zone.ipni_io.id

  managed_by = "Managed by Terraform: github.com/ipni/terraform-deployments"
}

import {
  to = cloudflare_zone.ipni_io
  id = "adc94c436b9dabcc27602fb18f09299e"
}

resource "cloudflare_zone" "ipni_io" {
  account = { id = local.account_id }
  name    = "ipni.io"
  type    = "full"

  lifecycle {
    # Deleting it would drop every record and rule in it, and once it is the
    # live zone, take ipni.io offline.
    prevent_destroy = true
  }
}

# ipni.io stays on the Free plan. A plan change is a billing action, made by a
# Super Administrator in the dashboard (the CI tokens have no billing access),
# and is not managed here: `plan` is read-only, so it shows up as no drift.
