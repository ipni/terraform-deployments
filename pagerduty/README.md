# PagerDuty

Who is on call for IPNI, and where pages go. The paging runbook is in
[ipni/infra](https://github.com/ipni/infra) (`docs/02-operation.md`, Paging).

| Resource | What |
|---|---|
| Team **ipni** and its members | `pagerduty_team`, `pagerduty_user`, `pagerduty_team_membership` |
| Schedule **IPNI on-call** | One person at a time, a week each, handing over on Monday at 09:00 UTC, in alias order |
| Escalation policy **IPNI** | The person on call, then everyone after 15 minutes; runs twice. Was the account's "Default" policy |
| Service **Service Worker Gateway** | Paged by Cloudflare when inbrowser.link is down (`production_down_page` in `cloudflare/notifications`). Was the "Default Service" that connecting Cloudflare created; its Cloudflare integration isn't managed here |
| Service **IPNI indexers** | The indexers on sf and sf2, paged by grafana.ipni.io through its **Events API v2** integration |
| Service **needle** | The routing service on the k3s boxes (sing1, lith1, chic1) and the boxes themselves, paged by the hub's Alertmanager (ipni/infra, lith1) through its **Events API v2** integration |

State: `s3://ipni-terraform-state/pagerduty/terraform.tfstate`. CI plans and
applies it with the Cloudflare stacks (same workflow, same approval).

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

```sh
terraform output -raw needle_integration_key | pbcopy
```

Both integrations have `prevent_destroy`: recreating one would change its key,
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
