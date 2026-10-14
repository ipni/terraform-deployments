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

# Created in the UI.
resource "pagerduty_team" "ipni" {
  name        = "ipni"
  description = local.managed_by
}

import {
  to = pagerduty_team.ipni
  id = "PWRBIVW"
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

resource "pagerduty_team_membership" "member" {
  for_each = local.aliases

  team_id = pagerduty_team.ipni.id
  user_id = pagerduty_user.member[each.key].id
}

import {
  for_each = local.existing_users

  to = pagerduty_team_membership.member[each.key]
  id = "${each.value}:PWRBIVW"
}

# One person on call at a time, a week each, handing over on Monday at 09:00
# UTC, in alias order.
resource "pagerduty_schedulev2" "on_call" {
  name        = "IPNI on-call"
  description = local.managed_by
  time_zone   = "Etc/UTC"
  teams       = [pagerduty_team.ipni.id]

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
  teams       = [pagerduty_team.ipni.id]

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

# Paged by Cloudflare when inbrowser.link is down (production_down_page in
# cloudflare/notifications). This was the account's "Default Service":
# connecting Cloudflare in its dashboard created it with the Cloudflare
# integration, which stays outside Terraform. Cloudflare never resolves the
# incident, so it neither times out nor auto-resolves: resolve it by hand.
resource "pagerduty_service" "swg" {
  name                    = "Service Worker Gateway"
  description             = "inbrowser.link, paged by Cloudflare Notifications. ${local.managed_by}"
  escalation_policy       = pagerduty_escalation_policy.ipni.id
  acknowledgement_timeout = "null"
  auto_resolve_timeout    = "null"
}

import {
  to = pagerduty_service.swg
  id = "P43ELBB"
}

# Paged by Alertmanager in ipni/infra and by grafana.ipni.io, through the
# Events API v2 integration below.
resource "pagerduty_service" "indexers" {
  name              = "IPNI indexers"
  description       = "Paged by Alertmanager (ipni/infra) and grafana.ipni.io. ${local.managed_by}"
  escalation_policy = pagerduty_escalation_policy.ipni.id
}

resource "pagerduty_service_integration" "indexers_events" {
  name    = "Events API v2"
  service = pagerduty_service.indexers.id
  type    = "events_api_v2_inbound_integration"

  # Recreating it changes the integration key, and Alertmanager and Grafana
  # would silently stop paging until both were updated.
  lifecycle {
    prevent_destroy = true
  }
}
