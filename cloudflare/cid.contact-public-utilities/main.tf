# cid.contact in the Cloudflare account "IPFS Public Utilities", where the
# zone is moving from "Alex@ipfs.io's Account" (managed by hand there).
#
# The zone was added by hand in the dashboard and is imported below: the CI
# tokens are scoped to single zones, so they cannot create one. It stays
# Pending and serves nothing until the domain moves here. cid.contact is
# registered with Squarespace, not Cloudflare Registrar, so the move is a
# nameserver change at Squarespace to this zone's `name_servers` (output).
# The zone's DNS records, settings and Pages project come here before that,
# so nothing goes missing when it lands.
#
# The zone is on the Enterprise plan. The plan is a billing change, made by a
# Super Administrator of the account in the dashboard: the CI tokens have no
# billing access, so it is neither managed nor checked here. Settings and
# rules that only exist on Enterprise are not part of this mirror.

locals {
  # Cloudflare account "IPFS Public Utilities" (shared with other IPFS services).
  account_id = "0b45911a8258997976f8efdec3ec84c1"
  zone_id    = cloudflare_zone.cid_contact.id

  managed_by = "Managed by Terraform: github.com/ipni/terraform-deployments"
}

import {
  to = cloudflare_zone.cid_contact
  id = "51b3ace740d2aa43892cc23443dc80d6"
}

resource "cloudflare_zone" "cid_contact" {
  account = { id = local.account_id }
  name    = "cid.contact"
  type    = "full"

  lifecycle {
    # Deleting it would drop every record in it, and once it is the live
    # zone, take cid.contact offline.
    prevent_destroy = true
  }
}
