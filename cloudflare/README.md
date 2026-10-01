# Cloudflare

Terraform for IPNI-owned config in the shared Cloudflare account
*IPFS Public Utilities*. Each folder is its own stack with its own state.

| Folder | What |
|---|---|
| `inbrowser.link/` | Production [Service Worker Gateway](https://github.com/ipfs/service-worker-gateway) zone, plus the Pages project it shares with staging |
| `inbrowser.dev/` | Staging Service Worker Gateway zone |
| `load-balancing/` | Account-level load balancer pools and health monitors used by both zones |
| `notifications/` | Cloudflare Notifications (alerts) for the gateway, sent to Slack and email |
| `modules/swg-zone/` | Shared zone config: DNS, zone settings, rulesets, load balancers, Pages custom domain, health check |
| `scripts/export.sh` | Read-only export of a live zone into `scripts/generated/` (git-ignored) |

## Not managed here

- **Site content and snippets.** The `ipfs/service-worker-gateway` repo deploys
  the Pages site (`wrangler pages deploy`) and the Cloudflare Snippets with their
  rules (`.github/scripts/deploy-snippets.sh`).
- **Other load balancer monitors and pools in the account** (needle, someguy,
  p2p-forge, ...). They belong to other services.
- **Cloudflare-managed rulesets** (OWASP, DDoS, managed WAF).

## Usage

**Don't change these zones, pools or alerts in the Cloudflare dashboard.**
Everything managed here is labelled "Managed by Terraform" there. A dashboard
edit is reported to #ipni-alerts by the nightly drift check and blocks the
next apply until it's synced into the code.

**You don't need any credentials to make a change.** Edit the code on a branch,
open a PR, read the plan CI posts on it, and merge (or turn on auto-merge).
Merging applies it, and the result is posted to #ipni-alerts. See
[Common changes](#common-changes) below.

Planning locally is optional. Only ever run `plan` locally; the state is
locked while anyone (CI or a laptop) runs, so nobody can overwrite someone
else's state.

This repo is public. Values that must stay private (the Rainbow origin
addresses, alert emails, Slack webhook) are not in it: CI reads them from
repository secrets, and for local plans you put them in a git-ignored
`secrets.auto.tfvars` in the stack folder. Copy them from
`terraform-values/` in the private `ipni/infra` repo. Without them, `plan`
stops and asks for the missing variables instead of planning a deletion.

```sh
export CLOUDFLARE_API_TOKEN=$(security find-generic-password -s cloudflare-api-token -w)
aws login   # Terraform >= 1.16 (required) reads the login session directly
cd inbrowser.link   # or inbrowser.dev, load-balancing, notifications
terraform init
terraform plan
```

State lives in `s3://ipni-terraform-state/cloudflare/<stack>/terraform.tfstate`
(bucket created by `bootstrap/state-backend`).

After adding or upgrading a provider, record its checksums for every platform,
or CI (Linux, `init -lockfile=readonly`) fails:

```sh
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_arm64 -platform=darwin_amd64
```

## Common changes

Try zone changes on `inbrowser.dev` first, then `inbrowser.link`.

- **DNS record, zone setting, rate limit, firewall or cache rule** (both
  zones): edit `modules/swg-zone/` (`dns.tf`, `zone_settings.tf`,
  `rulesets.tf`). For one zone only, add or change an input in that zone's
  `main.tf` (e.g. `rate_limit`, `cache_rules`, `extra_zone_settings`).
- **Gateway build CID** (`_dnslink.build-cid`): `dnslink_build_cid` in the
  zone's `main.tf`.
- **Load balancer pools or their order**: `load_balancers` in the zone's
  `main.tf`; pools and monitors themselves are in `load-balancing/main.tf`.
- **Alert**: add a `cloudflare_notification_policy` in `notifications/main.tf`
  using `local.mechanisms` (Slack + email) and `local.managed_by` in its
  description. Alert types and filters:
  `GET /accounts/<account>/alerting/v3/available_alerts`.
- **Alert recipients**: the `SWG_ALERT_EMAILS` secret (one-line JSON list) and
  `terraform-values/notifications.auto.tfvars` in the private `ipni/infra`.
- **Something new**: create it in code. If it already exists in Cloudflare,
  write the resource and an `import` block with its ID in the same PR; the plan
  should show the import and no other change. Remove the `import` block in a
  later PR.

Put "Managed by Terraform" in the description or comment of anything new that
has one (`local.managed_by`), so it's labelled in the dashboard too.

### When Cloudflare differs from the code (drift)

You'll see it as a :warning: post in #ipni-alerts from the nightly check, or
as an apply that stopped after a merge. Someone changed Cloudflare outside
this repo. Then either:

- **keep the change**: update the code to match (use
  [Re-exporting](#re-exporting) to see the live config), open a PR, and check
  its plan shows no changes for that resource; or
- **undo it**: open a PR that touches that stack (a comment is enough). Its
  plan shows the dashboard change being reverted; merging applies the revert.

## Load balancing

`load-balancing/` manages the pools `ovh-bhs-rainbow`, `ovh-eri-rainbow`,
`pages-production`, `pages-staging` and their monitors (`Rainbow HTTP monitor`,
`pages-prod`, `pages-staging`). The zone stacks read the pool IDs from its
`pool_ids` output through `terraform_remote_state`, so apply it before the zones
when adding or replacing a pool.

The Rainbow pools and their monitor are shared with ipfs.io, dweb.link,
trustless-gateway.link and others. Changes here affect all of them, and
dashboard edits made for those services show up here as drift.

Try changes on `inbrowser.dev` first. Differences between the zones are the
inputs in each `main.tf`.

## Alerts

`notifications/` sends these to Slack #ipni-alerts and to `alert_emails` (the
`SWG_ALERT_EMAILS` secret):

| Alert | Fires when |
|---|---|
| SWG load balancer pool health | A Rainbow or Pages pool, or one of its origins, goes unhealthy or recovers |
| SWG traffic anomalies | Traffic on either zone spikes or drops unusually |
| SWG Pages deployment failed | A production or staging deployment of `ipfs-service-worker-gateway` fails |

There is no origin 5xx error rate alert (`http_alert_origin_error`): Cloudflare
rejected `slo = ["99.5"]` with error 17007 (its thresholds are fixed per
sensitivity level). To add it back, create it in the dashboard, read its filters
from the API and import it.

The health check (`modules/swg-zone/health_checks.tf`) requests
`https://<cid>.ipfs.<zone>/` with a browser user agent and expects the Service
Worker Gateway bootstrap page. The gateway never fetches the CID server-side, so
it proves the gateway (DNS, load balancer, Snippets, origin) is up, not that the
content is retrievable.

The Slack webhook URL is a secret: CI reads it from `SWG_ALERTS_SLACK_WEBHOOK_URL`;
locally, `export TF_VAR_slack_webhook_url=...` before planning `notifications`,
or the plan will remove the Slack destination.

`notifications/` reads the pool IDs from the load-balancing state. An alert on
the `swg-ipfs-subdomain` health checks is added in a follow-up PR once the zones
have applied them (its plan needs their IDs).

## CI

`.github/workflows/terraform-cloudflare.yml`. **Merging a PR is the approval.**

1. **Pull request**: plans each affected stack and posts the full plan as a PR
   comment. Read it before merging; the `Terraform plan` check must pass. No
   review is required (small team): you can merge your own PR, or turn on
   auto-merge and it merges once the checks pass.
2. **Merge to main**: whoever merged the PR (or turned on its auto-merge) must
   be in the `TERRAFORM_APPROVERS` repo variable.
3. **Approve the deployment**: the apply job waits in the `production`
   environment. A code owner (TakGN, byo or nymd; they get a GitHub
   notification) opens the run, checks the plan, and clicks *Review
   deployments → Approve*. Nothing reaches Cloudflare until then; AI agents
   working in this repo never approve it. Then, for each affected stack, in the order `load-balancing`,
   `inbrowser.link`, `inbrowser.dev`, `notifications`: plan again, compare with
   the plan last posted on the merged PR, and apply only if they are the same.
4. **If the plans differ** (most often a dashboard change after the PR was
   planned), that stack and the ones after it are not applied and the run fails
   with the diff. Sync the change into the code in a new PR (see the drift
   steps under Load balancing) and merge it.

A manual run (Actions → Terraform (Cloudflare) → Run workflow) only plans, e.g.
to check for drift. Nothing applies except a merge.

Why this cannot overwrite state: every plan and apply holds the S3 state lock,
so runs (and laptops) queue instead of writing at the same time, and only
workflow runs on `main` can assume the AWS role that writes state.

`main` is protected (PR with passing `Terraform plan` and `gitleaks` checks,
no force pushes), and the workflow checks the rules again itself: only a merged
PR applies, it must be merged by someone in `TERRAFORM_APPROVERS`, and its plan
must still match. A direct push to `main` applies nothing.

### Public repo safeguards

- No secrets or private values in the code; `Secret scan` (gitleaks) fails any
  PR or push that adds one, and GitHub push protection blocks it earlier.
- Pull requests from forks get no secrets and no OIDC token, and their plan is
  skipped. To take an outside change, re-open it from a branch in this repo
  after reading it: a plan runs PR code with the read-only token.
- Sensitive variables are `sensitive = true`, so plans, PR comments and logs
  show `(sensitive value)` instead of them.
- Actions are pinned to commit SHAs; Dependabot proposes updates.

### One-time setup

1. **AWS roles** (someone with IAM rights):
   ```sh
   cd bootstrap/github-actions && terraform init && terraform apply
   ```
2. **Cloudflare API tokens** (dashboard → My Profile → API Tokens), scoped to the
   *IPFS Public Utilities* account and the `inbrowser.link` / `inbrowser.dev` zones:
   - read-only for plans: Account Load Balancing: Monitors and Pools, Notifications,
     Cloudflare Pages; Zone, DNS, Load Balancers, Health Checks, Zone Settings,
     Zone WAF, Cache Rules, Config Rules, SSL and Certificates: **Read**
   - the same permissions with **Edit** for applies
3. **Repository settings** (Settings → Secrets and variables → Actions):
   - secrets `AWS_ROLE_TERRAFORM_CLOUDFLARE_PLAN` and
     `AWS_ROLE_TERRAFORM_CLOUDFLARE_APPLY`: the role ARNs output in step 1
     (not secret, but stored as secrets so the account ID stays out of the
     public logs)
   - variable `TERRAFORM_APPROVERS`: who can approve applies, space separated
     (`TakGN byo nymd`)
   - secrets `CLOUDFLARE_API_TOKEN_READ` (read-only token),
     `CLOUDFLARE_API_TOKEN` (edit token), `SWG_ALERTS_SLACK_WEBHOOK_URL`
     (Slack incoming webhook), `RAINBOW_ORIGINS` and `SWG_ALERT_EMAILS`
     (one-line JSON, the same values as in `ipni/infra/terraform-values/`)
4. **Repository security settings**: branch protection on `main` (require a PR,
   no review, required checks `Terraform plan` and `gitleaks`, no force pushes
   or deletion); allow auto-merge; Actions → require approval for all outside contributors;
   Actions → workflow permissions read-only; secret scanning and push
   protection on.
5. **`production` environment** (Settings → Environments): required reviewers
   TakGN, byo, nymd (the code owners); deployment branches: protected branches
   only. The apply role in `bootstrap/github-actions` trusts only jobs in this
   environment.

## Re-exporting

```sh
scripts/export.sh -z inbrowser.dev
```

Compare `scripts/generated/<zone>/` with the stack to spot changes made in the
dashboard. Check exported cache rules by hand: `cf-terraforming` writes
`query_string.exclude = null` where the live rule has `exclude = { all = true }`.
