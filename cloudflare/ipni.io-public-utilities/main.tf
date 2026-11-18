# ipni.io in the Cloudflare account "IPFS Public Utilities", where the zone is
# moving from "Alex@ipfs.io's Account" (still managed in ../ipni.io until the
# move is done).
#
# The zone was added by hand in the dashboard and is imported below: the CI
# tokens are scoped to single zones, so they cannot create one. It stays
# Pending and serves nothing until the domain moves here. ipni.io is
# registered with Cloudflare Registrar, so the move is Cloudflare's
# inter-account registrar transfer, started from the old account, not a
# nameserver change. The zone's DNS records, rules and settings come here
# before that transfer, so nothing goes missing when it lands.

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

# The plan is a billing change, made by a Super Administrator of the account
# in the dashboard (Overview > Active Subscriptions > Change): the CI tokens
# have no billing access. `plan` is read-only here, so the change shows up as
# no drift; this check only warns on every plan until it is done.
check "enterprise_plan" {
  assert {
    condition     = cloudflare_zone.ipni_io.plan.legacy_id == "enterprise"
    error_message = "ipni.io is on the ${cloudflare_zone.ipni_io.plan.name} plan, not Enterprise. A Super Administrator of IPFS Public Utilities changes it in the dashboard."
  }
}
