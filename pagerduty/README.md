# PagerDuty

Who is on call for IPNI, and where pages go. The paging runbook is in
[ipni/infra](https://github.com/ipni/infra) (`docs/02-operation.md`, Paging).

| Resource | What |
|---|---|
| Members | `pagerduty_user` (no team: see [Plan](#plan)) |
| Schedule **IPNI on-call** | One person at a time, a week each, handing over on Monday at 09:00 UTC, in alias order |
| Escalation policy **IPNI** | The person on call, then everyone after 15 minutes; runs twice. Was the account's "Default" policy |
| Service **Service Worker Gateway (inbrowser.link)** | Fetches and verifies IPFS content in the visitor's browser. Paged by Cloudflare when inbrowser.link is down (`production_down_page` in `cloudflare/notifications`). Was the "Default Service" that connecting Cloudflare created; its Cloudflare integration isn't managed here |
| Service **IPNI indexers (cid.contact)** | Map CIDs to the providers that advertise them (storetheindex on sf and sf2). Paged by grafana.ipni.io through its **Events API v2** integration |
| Service **Delegated routing (needle)** | Answers provider, peer and IPNS lookups for delegated-ipfs.dev from the Amino DHT and cid.contact, on the k3s boxes (sing1, lith1, chic1). Also gets the boxes' own alerts (box down, ZFS pool) |
| Service **Routing origin (route-origin)** | The Envoy in front of needle: the origin of delegated-ipfs.dev and `route-<box>.ipni.io`, with TLS, the path allowlist and rate limits |
| Service **IPFS bootstrap peers (bootstrap)** | The kubo nodes new IPFS peers dial to join the network (`bootstrap.ipni.io` and the legacy `bootstrap.libp2p.io` PeerIDs), with WSS for browsers |
| Service **IPFS website hosting (content)** | kubo and ipfs-cluster pinning the IPFS Project websites on every box, and the `pin.ipni.io` remote pinning API |
| Business services | **delegated-ipfs.dev**, **cid.contact**, **inbrowser.link**, **bootstrap.ipni.io**, **IPFS Project websites**: what users reach, each depending on the services behind it (`dependencies.tf`) |
| Service dependencies | gateway → route-origin → needle → indexers, and content → bootstrap (`dependencies.tf`) |

The four k3s-box services are each paged by the hub's Alertmanager (ipni/infra,
lith1) through their own **Events API v2** integration, so the incident names
the service. Box-level alerts stay on **Delegated routing (needle)**.

State: `s3://ipni-terraform-state/pagerduty/terraform.tfstate`. CI plans and
applies it with the Cloudflare stacks (same workflow, same approval).

## Plan

We stay on PagerDuty's **Free** plan: up to 5 users, one schedule and one
escalation policy, with the API and integrations included, and 100 phone or
SMS notifications a month (push through the app isn't capped). Teams are a
paid feature, so nothing here uses one: who is paged comes from the schedule
and the escalation policy. The team `ipni` created in the UI is no longer
managed by Terraform. A 6th person, or a second rotation, needs a paid plan.

## Service standards

PagerDuty scores every service against its standards (Service Directory →
Standards). Where each stands:

| Standard | How it's met |
|---|---|
| Has a description | `description` on every service |
| Escalation policy with 2+ unique levels | The **IPNI** policy: the schedule, then everyone |
| At least 1 API integration | Events API v2 on every service but the gateway, which has Cloudflare's |
| Does not only send high urgency incidents | `severity_based` urgency on every service but the gateway: Grafana and Alertmanager send `severity=critical`, so their pages stay high. The gateway keeps constant high urgency (what severity Cloudflare sends isn't known) and is **excluded** from this standard |
| At least 1 technical service dependency | `pagerduty_service_dependency.technical` |
| At least 1 business service dependency | `pagerduty_business_service.public` and `pagerduty_service_dependency.business` |
| At least 1 change integration | **Excluded for every service.** Change events need the AIOps add-on, which the Free plan doesn't have |
| Has an extension or add-on (e.g. Slack) | **Not met yet.** It needs the PagerDuty Slack app in the Filecoin Slack workspace (approved by its admins), then a `pagerduty_slack_connection` per service to #ipni-alerts |

The provider can read standards but not change them, so exclusions are set in
the dashboard: Service Directory → Standards → the standard → Exclusions.

## Not managed here

- **Each person's contact methods and notification rules** (app, SMS, phone):
  everyone sets up their own in PagerDuty.
- **The Cloudflare → PagerDuty connection**: an authorization flow in the
  Cloudflare dashboard (see [Paging](../cloudflare/README.md#paging)). It
  created the Cloudflare integration on the **Service Worker Gateway** service
  (`terraform output swg_service_id`); reconnecting it should pick that
  service again.
- **Profiles**: job title, time zone, colour, avatar. Terraform only sets
  name, email, role and the "Managed by Terraform" description.

## Members

Names and emails are private, so they aren't in the code: CI reads them from
the `PAGERDUTY_MEMBERS` secret (and its copy in the 1Password note, see
[cloudflare/README.md](../cloudflare/README.md#usage)), one-line JSON keyed by
a public alias, their GitHub handle:

```json
{"alice": {"id": "PABC123", "name": "Alice …", "email": "alice@…", "role": "user"}}
```

- `role`: `owner`, `admin`, `user` or `limited_user`. An API key can't
  modify the account owner at all (403), so keep the owner as `owner` and let
  them change their own name or email in PagerDuty, then in the secret.
- `id`: an existing PagerDuty user, imported. Leave it out for someone new:
  merging creates the user, and PagerDuty emails them an invitation.
- `on_call` (default `true`): `false` keeps them out of the weekly rotation;
  they're still paged at the second escalation step.

Removing someone from the secret deletes their PagerDuty user. Aliases show
in plans; the rest shows as `(sensitive value)`.

To add or remove someone: update the secret and the 1Password note, then open
a PR touching this folder (a comment is enough) so CI plans it.

## Integration keys

Each service has its own Events API v2 integration key. They're outputs marked
sensitive, so CI never prints them. Read one locally and store it where its
sender reads it:

| Output | Sender | Stored in |
|---|---|---|
| `indexers_integration_key` | grafana.ipni.io (sf, sf2) | Grafana: the PagerDuty contact point |
| `needle_integration_key` | Alertmanager on lith1 | ipni/infra SOPS: `alertmanager-secrets` → `pagerduty-routing-key` |
| `bootstrap_integration_key` | Alertmanager on lith1 | ipni/infra SOPS: `alertmanager-secrets` → `pagerduty-bootstrap-routing-key` |
| `content_integration_key` | Alertmanager on lith1 | ipni/infra SOPS: `alertmanager-secrets` → `pagerduty-content-routing-key` |
| `route_origin_integration_key` | Alertmanager on lith1 | ipni/infra SOPS: `alertmanager-secrets` → `pagerduty-route-origin-routing-key` |

```sh
terraform output -raw needle_integration_key | pbcopy
```

Every integration has `prevent_destroy`: recreating one would change its key,
and its sender would silently stop paging.

## Local plan

```sh
export PAGERDUTY_TOKEN=...   # read-only API key
op read "op://Compass/terraform-deployments GitHub Actions secrets/PAGERDUTY_MEMBERS" \
  | jq '{members: .}' > secrets.auto.tfvars.json
aws login
terraform init
terraform plan
```

## One-time setup

1. **API keys** (PagerDuty → Integrations → API Access Keys): a read-only key
   as the repository secret `PAGERDUTY_TOKEN_READ` (plans), and a full-access
   key as `PAGERDUTY_TOKEN`, a secret of the `production` environment
   (applies). Both in the 1Password note too.
2. **`PAGERDUTY_MEMBERS`** repository secret, as above.
3. **AWS roles**: `bootstrap/github-actions` gives the CI roles the
   `pagerduty/` state prefix; apply it by hand before the first PR that
   touches this folder is planned.
