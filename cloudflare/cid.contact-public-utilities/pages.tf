# filecoin-redirect (github.com/ipni/filecoin-redirect), the redirect service
# on direct.cid.contact and fetch.cid.contact, mirrored from the Pages project
# of the same name in Alex@ipfs.io's Account. Project settings only: Pages
# builds and deploys the site itself on every push to the repo.
#
# Not created until the cutover. A GitHub repository can only be connected to
# Pages projects in one Cloudflare account, so Cloudflare refuses this project
# (error 8000093) while the old one exists. A project without the repository
# is no way around it: a direct-upload project can't be connected to Git later.
#
# Until then, direct. and fetch.cid.contact point at the old project's
# filecoin-redirect.pages.dev, as in the old zone. At the cutover, after the
# nameserver change:
#   1. delete the old project in Alex@ipfs.io's Account (direct. and
#      fetch.cid.contact are down until step 2 is applied);
#   2. set filecoin_redirect_cutover to true: this creates the project,
#      connected to the repository, with both hostnames as its custom domains,
#      and points the CNAMEs at it. Its pages.dev name is
#      filecoin-redirect.pages.dev again if Cloudflare has freed it, else a
#      generated one.

locals {
  filecoin_redirect_cutover = false

  filecoin_redirect_hostnames = ["direct.cid.contact", "fetch.cid.contact"]

  # The repo's wrangler.toml sets these on every deployment (the dashboard
  # shows them read-only). They are set here too so the project starts with
  # the same values, and ignored afterwards, below.
  filecoin_redirect_deployment_config = {
    always_use_latest_compatibility_date = false
    build_image_major_version            = 3
    compatibility_date                   = "2026-10-08"
    # Not computed by the provider: left out, the API's [] would show as a diff.
    compatibility_flags = []
    fail_open           = true
    env_vars = {
      CACHE_TTL_SECONDS = { type = "plain_text", value = "300" }
      INDEXER_URL       = { type = "plain_text", value = "https://cid.contact" }
    }
  }
}

resource "cloudflare_pages_project" "filecoin_redirect" {
  count = local.filecoin_redirect_cutover ? 1 : 0

  account_id        = local.account_id
  name              = "filecoin-redirect"
  production_branch = "main"

  # The output directory also comes from wrangler.toml; the build command
  # cannot, and without it the Functions build fails (see the repo's README).
  build_config = {
    build_command   = "npm ci"
    destination_dir = "public"
    root_dir        = ""
  }

  deployment_configs = {
    preview    = local.filecoin_redirect_deployment_config
    production = local.filecoin_redirect_deployment_config
  }

  source = {
    type = "github"
    config = {
      owner                          = "ipni"
      owner_id                       = "115147265"
      repo_name                      = "filecoin-redirect"
      repo_id                        = "1410645470"
      production_branch              = "main"
      production_deployments_enabled = true
      pr_comments_enabled            = true
      preview_deployment_setting     = "all"
      preview_branch_includes        = ["*"]
      path_includes                  = ["*"]
    }
  }

  lifecycle {
    # Owned by wrangler.toml in ipni/filecoin-redirect: each deployment writes
    # them, so a change there is not drift here.
    ignore_changes = [
      deployment_configs.preview.compatibility_date,
      deployment_configs.preview.env_vars,
      deployment_configs.preview.wrangler_config_hash,
      deployment_configs.production.compatibility_date,
      deployment_configs.production.env_vars,
      deployment_configs.production.wrangler_config_hash,
    ]
  }
}

resource "cloudflare_pages_domain" "filecoin_redirect" {
  for_each = local.filecoin_redirect_cutover ? toset(local.filecoin_redirect_hostnames) : toset([])

  account_id   = local.account_id
  project_name = cloudflare_pages_project.filecoin_redirect[0].name
  name         = each.key
}
