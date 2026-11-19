# filecoin-redirect (github.com/ipni/filecoin-redirect), the redirect service
# on direct.cid.contact and fetch.cid.contact, moving from the Pages project
# "filecoin-redirect" in Alex@ipfs.io's Account. Project settings only: Pages
# builds and deploys the site itself on every push to the repo.
#
# A GitHub repository can only be connected to Pages projects in one Cloudflare
# account (error 8000093 otherwise). The repository was disconnected from the
# old project, which keeps serving its last deployment on
# filecoin-redirect.pages.dev, direct.cid.contact and fetch.cid.contact. This
# project gets its own name, so it doesn't depend on Cloudflare freeing
# "filecoin-redirect".
#
# In two steps, so direct. and fetch.cid.contact keep working:
#   1. this project is created and builds from the repo, on
#      ipni-filecoin-redirect.pages.dev (filecoin_redirect_cutover = false);
#   2. once this zone is active (nameserver change at Squarespace), set
#      filecoin_redirect_cutover to true: this adds both hostnames as its
#      custom domains, then points the CNAMEs at it (dns.tf). If Cloudflare
#      refuses a domain as in use, remove it from the old project first. Then
#      delete the old project.

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

# Provider 5.26.0 to 5.29.0 bug: the create and update responses don't match
# what was sent for sensitive attributes (build_config's web_analytics_token,
# the env_vars values), which fails the apply as an "inconsistent result". The
# create (#64) failed that way and left the project tainted, untainted by hand.
#
# build_config is left out, as for ipni-cidstats: kept in the code, even
# ignored, the provider plans its unset members as unknown, an update on every
# plan. #64 created the project with build command `npm ci` and output
# directory `public` (the Functions build fails without `npm ci`, and it can't
# be set in wrangler.toml); add them back here if the project is ever
# recreated.
resource "cloudflare_pages_project" "filecoin_redirect" {
  account_id        = local.account_id
  name              = "ipni-filecoin-redirect"
  production_branch = "main"

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
    ignore_changes = [
      # Owned by wrangler.toml in ipni/filecoin-redirect: each deployment
      # writes them, so a change there is not drift here.
      deployment_configs.preview.compatibility_date,
      deployment_configs.preview.env_vars,
      deployment_configs.preview.placement,
      deployment_configs.preview.wrangler_config_hash,
      deployment_configs.production.compatibility_date,
      deployment_configs.production.env_vars,
      deployment_configs.production.placement,
      deployment_configs.production.wrangler_config_hash,
    ]
  }
}

resource "cloudflare_pages_domain" "filecoin_redirect" {
  for_each = local.filecoin_redirect_cutover ? toset(local.filecoin_redirect_hostnames) : toset([])

  account_id   = local.account_id
  project_name = cloudflare_pages_project.filecoin_redirect.name
  name         = each.key
}
