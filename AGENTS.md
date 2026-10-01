# AGENTS.md

Guidance for AI coding agents working in this repo. Humans: see
[README.md](README.md) and [cloudflare/README.md](cloudflare/README.md).

## What this is

Terraform for IPNI infrastructure:

- `cloudflare/`: the Service Worker Gateway zones (`inbrowser.link` production,
  `inbrowser.dev` staging), their load balancer pools and monitors, and alerts.
  Applied by CI when a PR is merged.
- `bootstrap/`: the S3 state bucket and the IAM roles CI assumes. Applied by
  hand by humans with IAM rights, never by CI.

The repo is **public**, and the Cloudflare account is shared with other IPFS
services (ipfs.io, dweb.link, trustless-gateway.link, ...).

## Hard rules

- **Never commit private values**: origin addresses, IPs, email addresses,
  tokens, webhook URLs, credentials. Add them as variables with
  `sensitive = true`, set in CI from repository secrets (`TF_VAR_*` in
  `.github/workflows/terraform-cloudflare.yml`) and locally from a git-ignored
  `secrets.auto.tfvars`. Don't print them in output or PR text either.
- **Never run `terraform apply`** (or `import`, `state rm`, `state mv`,
  `force-unlock`). Merging a PR is the only way to apply. You may run `fmt`,
  `validate` and `plan`.
- **Don't change `bootstrap/`** unless asked; a human applies it by hand.
- **The Rainbow pools and their monitor** (`cloudflare/load-balancing`) are
  shared with ipfs.io and others: any change there affects them too. Try zone
  changes on `inbrowser.dev` first.
- **Don't weaken CI**:
  - no `pull_request_target` or `workflow_run` on PR code;
  - keep actions pinned to a commit SHA with the version in a comment;
  - never widen the AWS OIDC trust in `bootstrap/github-actions`. It uses
    GitHub's immutable subject
    `repo:ipni@115147265/terraform-deployments@1400567172:...`; keep it exact,
    with no wildcards.
- **No major-version upgrades** (Terraform, providers, actions) unless asked.
  Minor and patch only; Dependabot is set up the same way.

## Layout and stack order

Each folder under `cloudflare/` is its own stack with its own state in
`s3://ipni-terraform-state/cloudflare/<stack>/`. CI applies them in this order
(`STACK_ORDER` in the workflow), because later stacks read earlier ones through
`terraform_remote_state`:

1. `load-balancing`: pools and monitors; outputs `pool_ids`.
2. `inbrowser.link`, `inbrowser.dev`: both use `modules/swg-zone`; the
   differences between the zones are the inputs in each `main.tf`.
3. `notifications`: alerts; reads the pool IDs. It runs last so it can also
   use IDs the zones create (e.g. health checks).

Adding a stack: add it to `STACK_ORDER`, keep its state key under
`cloudflare/` (the CI roles can only reach that prefix), and add its README row.

## Commands

Requires Terraform >= 1.16, `aws login`, and `CLOUDFLARE_API_TOKEN`.

```sh
terraform fmt -check -recursive        # from the repo root
cd cloudflare/<stack>
terraform init -lockfile=readonly
terraform validate
terraform plan
```

After adding or upgrading a provider, record checksums for every platform or
CI fails:

```sh
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_arm64 -platform=darwin_amd64
```

`actionlint` checks workflow changes.

## How changes ship

1. Open a PR. CI plans every affected stack and posts the plan as a comment.
   The required checks are `Terraform plan` and `gitleaks`.
2. Merging applies. Whoever merges must be in the `TERRAFORM_APPROVERS` repo
   variable; no review is required.
3. On merge, CI plans again and applies only if the plan matches the one on
   the PR. If not (usually a dashboard edit), it stops: sync the drift into
   the code in a new PR. Never work around the check.

In the PR description, say what the plan is expected to show, and explain any
change you didn't intend (the PR template asks for it).

Applies are posted to Slack #ipni-alerts, and a nightly scheduled plan posts
any drift there. Give anything new a "Managed by Terraform" label in its
description or comment (`local.managed_by`) so it's marked in the dashboard.

## Known gotchas

- **Cloudflare provider minor versions** can add attributes, which shows up as
  in-place updates on many resources (5.26.0 added `include_shadow_metadata`
  to every DNS record). Check that only the new attribute changes.
- **Slack webhook** (`notifications`): has `ignore_changes = [url]`, because
  Cloudflare returns the URL without its secret part. To change it, replace
  the resource.
- **Origin error rate alert** (`http_alert_origin_error`): Cloudflare only
  accepts fixed `slo` values and rejected `99.5` (error 17007). It isn't
  managed here; to add it, create it in the dashboard and import it.
- **Local plans of `notifications`** remove the Slack destination unless
  `TF_VAR_slack_webhook_url` is set. That is a local artefact, not a change.
- **`sensitive` variables** make values show as `(sensitive value)`, and
  marking an existing value sensitive shows as an in-place update with no real
  change.
- **Dependabot PRs** get no secrets, so their plans fail. A maintainer pushes a
  commit to the branch to get a real plan.
- **`cloudflare/scripts/export.sh`** (cf-terraforming) writes
  `query_string.exclude = null` for cache rules where the live rule has
  `exclude = { all = true }`. Check exported cache rules by hand.

## Style

- Match the surrounding HCL: short comments that say why, not what.
- Commit messages: imperative subject line, a body explaining why.
