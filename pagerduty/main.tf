# PagerDuty for IPNI: who is on call and where pages go. The paging runbook is
# in ipni/infra (docs/02-operation.md, Paging). Each person's own contact
# methods and notification rules stay in PagerDuty: they set them up there.

locals {
  # Shown in PagerDuty on everything created here.
  managed_by = "Managed by Terraform: github.com/ipni/terraform-deployments"

  # The aliases aren't private, and for_each needs them in plain text. The
  # rest of each member (name, email) stays sensitive.
  aliases = toset(nonsensitive(keys(var.members)))

  # Users that already exist in PagerDuty (invited in the UI). User IDs aren't
  # private either.
  existing_users = { for a, m in nonsensitive(var.members) : a => m.id if m.id != null }

  # The rotation, in alias order. Who is on call isn't private.
  on_call = [for a in sort(local.aliases) : a if nonsensitive(var.members[a].on_call)]
}

# Teams are a paid feature, and we stay on the Free plan (5 users, one
# schedule, one escalation policy). Terraform no longer manages the team
# "ipni" or its memberships; they stay in PagerDuty until the plan drops them,
# and who is paged comes from the schedule and escalation policy anyway.
removed {
  from = pagerduty_team.ipni
  lifecycle {
    destroy = false
  }
}

removed {
  from = pagerduty_team_membership.member
  lifecycle {
    destroy = false
  }
}

resource "pagerduty_user" "member" {
  for_each = local.aliases

  name  = var.members[each.key].name
  email = var.members[each.key].email
  role  = var.members[each.key].role

  description = local.managed_by

  # Everyone edits their own profile in PagerDuty. The description is only set
  # on users Terraform creates: an API key can't modify the account owner
  # (403, code 2010), so updating it on the imported owner failed the apply.
  # The owner's name, email and role can only be changed by the owner, in
  # PagerDuty.
  lifecycle {
    ignore_changes = [job_title, description]
  }
}

import {
  for_each = local.existing_users

  to = pagerduty_user.member[each.key]
  id = each.value
}

# One person on call at a time, a week each, handing over on Monday at 09:00
# UTC, in alias order.
resource "pagerduty_schedulev2" "on_call" {
  name        = "IPNI on-call"
  description = local.managed_by
  # UTC all year (no daylight saving since 1972), and spelled so the provider
  # can round-trip it. With Etc/UTC, the provider reads PagerDuty's value back
  # as "UTC" (v3.36.0), which its own validator and the API both reject: plans
  # always showed a diff, and ignoring it made every schedule update fail
  # ("Timezone is not supported").
  time_zone = "Africa/Monrovia"

  rotation {
    event {
      name            = "Weekly"
      start_time      = "2026-10-19T09:00:00Z"
      end_time        = "2026-10-26T09:00:00Z"
      effective_since = "2026-10-19T09:00:00Z"
      recurrence      = ["RRULE:FREQ=WEEKLY"]

      assignment_strategy {
        type              = "rotating_member_assignment_strategy"
        shifts_per_member = 1

        dynamic "member" {
          for_each = [for a in local.on_call : pagerduty_user.member[a].id]
          content {
            type    = "user_member"
            user_id = member.value
          }
        }
      }
    }
  }
}

# The person on call, then everyone if nobody acknowledges within 15 minutes;
# the whole policy runs twice. This was the account's "Default" policy.
resource "pagerduty_escalation_policy" "ipni" {
  name        = "IPNI"
  description = local.managed_by
  num_loops   = 2

  rule {
    escalation_delay_in_minutes = 15
    target {
      type = "schedule_reference"
      id   = pagerduty_schedulev2.on_call.id
    }
  }

  rule {
    escalation_delay_in_minutes = 15
    dynamic "target" {
      for_each = pagerduty_user.member
      content {
        type = "user_reference"
        id   = target.value.id
      }
    }
  }
}

import {
  to = pagerduty_escalation_policy.ipni
  id = "PYI77LX"
}

# The Service Worker Gateway (inbrowser.link): fetches and verifies IPFS
# content in the visitor's browser. Paged by Cloudflare when inbrowser.link is
# down (production_down_page in cloudflare/notifications). This was the account's "Default Service":
# connecting Cloudflare in its dashboard created it with the Cloudflare
# integration, which stays outside Terraform. Cloudflare never resolves the
# incident, so it neither times out nor auto-resolves: resolve it by hand.
resource "pagerduty_service" "swg" {
  name                    = "Service Worker Gateway (inbrowser.link)"
  description             = "Fetches and verifies IPFS content in the visitor's browser, at inbrowser.link. Paged by Cloudflare Notifications. ${local.managed_by}"
  escalation_policy       = pagerduty_escalation_policy.ipni.id
  acknowledgement_timeout = "null"
  auto_resolve_timeout    = "null"
}

import {
  to = pagerduty_service.swg
  id = "P43ELBB"
}

# The indexers on sf and sf2 (storetheindex behind cid.contact): map CIDs to
# the providers that advertise them. Paged by grafana.ipni.io through the
# Events API v2 integration below.
resource "pagerduty_service" "indexers" {
  name              = "IPNI indexers (cid.contact)"
  description       = "Map CIDs to the providers that advertise them: storetheindex on sf and sf2, behind cid.contact. Paged by grafana.ipni.io. ${local.managed_by}"
  escalation_policy = pagerduty_escalation_policy.ipni.id
}

resource "pagerduty_service_integration" "indexers_events" {
  name    = "Events API v2"
  service = pagerduty_service.indexers.id
  type    = "events_api_v2_inbound_integration"

  # Recreating it changes the integration key, and Grafana would silently stop
  # paging until it was updated.
  lifecycle {
    prevent_destroy = true
  }
}

# needle, the delegated routing server on the k3s boxes (sing1, lith1, chic1)
# behind delegated-ipfs.dev: answers provider, peer and IPNS lookups from the
# Amino DHT and cid.contact. Also the boxes themselves (box down, ZFS pool).
# Paged by the hub's Alertmanager in ipni/infra (lith1).
resource "pagerduty_service" "needle" {
  name              = "Delegated routing (needle)"
  description       = "Answers provider, peer and IPNS lookups for delegated-ipfs.dev from the Amino DHT and cid.contact, on sing1, lith1 and chic1. Also gets the boxes' own alerts (box down, ZFS pool). Paged by Alertmanager on lith1 (ipni/infra). ${local.managed_by}"
  escalation_policy = pagerduty_escalation_policy.ipni.id
}

resource "pagerduty_service_integration" "needle_events" {
  name    = "Events API v2"
  service = pagerduty_service.needle.id
  type    = "events_api_v2_inbound_integration"

  # Recreating it changes the integration key, and Alertmanager would silently
  # stop paging until ipni/infra's SOPS secret was updated.
  lifecycle {
    prevent_destroy = true
  }
}

# The other priority services on the k3s boxes, each paged by the hub's
# Alertmanager for its own critical alerts (no ready pod, endpoint and libp2p
# probes), so an incident says which service is down. Box-level alerts stay on
# needle.

# bootstrap: the kubo nodes new IPFS peers dial to join the network, and the
# Envoy that gives browsers a WSS address for them.
resource "pagerduty_service" "bootstrap" {
  name              = "IPFS bootstrap peers (bootstrap)"
  description       = "kubo nodes that new IPFS peers dial to join the network (bootstrap.ipni.io and the legacy bootstrap.libp2p.io PeerIDs), with WSS for browsers. Paged by Alertmanager on lith1 (ipni/infra). ${local.managed_by}"
  escalation_policy = pagerduty_escalation_policy.ipni.id
}

resource "pagerduty_service_integration" "bootstrap_events" {
  name    = "Events API v2"
  service = pagerduty_service.bootstrap.id
  type    = "events_api_v2_inbound_integration"

  # Recreating it changes the integration key (see needle_events).
  lifecycle {
    prevent_destroy = true
  }
}

# content: kubo and ipfs-cluster pinning the IPFS Project websites on every
# box, and the Envoy in front of the pin.ipni.io pinning API.
resource "pagerduty_service" "content" {
  name              = "IPFS website hosting (content)"
  description       = "kubo and ipfs-cluster pinning the IPFS Project websites on every box, and the pin.ipni.io remote pinning API. Paged by Alertmanager on lith1 (ipni/infra). ${local.managed_by}"
  escalation_policy = pagerduty_escalation_policy.ipni.id
}

resource "pagerduty_service_integration" "content_events" {
  name    = "Events API v2"
  service = pagerduty_service.content.id
  type    = "events_api_v2_inbound_integration"

  # Recreating it changes the integration key (see needle_events).
  lifecycle {
    prevent_destroy = true
  }
}

# route-origin: the Envoy in front of needle, the origin of delegated-ipfs.dev
# and route-<box>.ipni.io (TLS, path allowlist, rate limits).
resource "pagerduty_service" "route_origin" {
  name              = "Routing origin (route-origin)"
  description       = "Envoy in front of needle: the origin of delegated-ipfs.dev and route-<box>.ipni.io, with TLS, the path allowlist and rate limits. Paged by Alertmanager on lith1 (ipni/infra). ${local.managed_by}"
  escalation_policy = pagerduty_escalation_policy.ipni.id
}

resource "pagerduty_service_integration" "route_origin_events" {
  name    = "Events API v2"
  service = pagerduty_service.route_origin.id
  type    = "events_api_v2_inbound_integration"

  # Recreating it changes the integration key (see needle_events).
  lifecycle {
    prevent_destroy = true
  }
}
