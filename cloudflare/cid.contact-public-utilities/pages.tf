# filecoin-redirect (github.com/ipni/filecoin-redirect), the redirect service
# on direct.cid.contact and fetch.cid.contact, mirrored from the Pages project
# of the same name in Alex@ipfs.io's Account. Project settings only: Pages
# builds and deploys the site itself on every push to the repo.
#
# The Cloudflare Pages GitHub app must be able to read ipni/filecoin-redirect
# from IPFS Public Utilities, or creating the project fails. It can today:
# the account's build API reads the repo's wrangler.toml.
#
# The name `filecoin-redirect.pages.dev` belongs to the old project, so this
# one gets a generated one (`filecoin-redirect-<random>.pages.dev`); the
# CNAMEs in dns.tf follow it.

locals {
  # Off until the cutover: direct.cid.contact and fetch.cid.contact are custom
  # domains of the old project, and a hostname can only belong to one project.
  # At the nameserver change: remove them from the old project, then set this
  # to true.
  filecoin_redirect_custom_domains = false

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
      # The old project already comments on every PR; turn this on when it is
      # deleted, so PRs don't get two comments.
      pr_comments_enabled        = false
      preview_deployment_setting = "all"
      preview_branch_includes    = ["*"]
      path_includes              = ["*"]
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
  for_each = local.filecoin_redirect_custom_domains ? toset(["direct.cid.contact", "fetch.cid.contact"]) : toset([])

  account_id   = local.account_id
  project_name = cloudflare_pages_project.filecoin_redirect.name
  name         = each.key
}
