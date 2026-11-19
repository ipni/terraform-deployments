# The cidstats site (github.com/ipni/cidstats), on cidstats.ipni.io. Moved from
# the Pages project "cidstats" in Alex@ipfs.io's Account. Project settings
# only: Pages builds and deploys the site itself on every push to the repo.
#
# A GitHub repository can only be connected to Pages projects in one Cloudflare
# account (error 8000093 otherwise), so the repository was disconnected from
# the old project first; that project kept serving its last deployment. This
# project has its own name, so it didn't depend on Cloudflare freeing
# "cidstats". It was created first, then cidstats.ipni.io was moved to it after
# the registrar transfer by setting cidstats_cutover to true, which adds the
# custom domain and points the CNAME at it (dns.tf). cidstats_cutover stays as
# a switch so the resource addresses don't change.

locals {
  cidstats_cutover = true

  cidstats_deployment_config = {
    always_use_latest_compatibility_date = false
    build_image_major_version            = 3
    compatibility_date                   = "2026-10-23"
    # Not computed by the provider: left out, the API's [] would show as a diff.
    compatibility_flags = []
    fail_open           = true
  }
}

# Provider 5.26.0 bug: its create and update responses don't match the
# build_config sent (a sensitive attribute inside it), which fails the apply as an
# "inconsistent result" (the create left the project tainted, untainted by hand).
# build_config is left out: the site is static files from the repo root with no
# build step, Pages' default, so there's nothing to set.
resource "cloudflare_pages_project" "cidstats" {
  account_id        = local.account_id
  name              = "ipni-cidstats"
  production_branch = "main"

  deployment_configs = {
    preview    = local.cidstats_deployment_config
    production = local.cidstats_deployment_config
  }

  source = {
    type = "github"
    config = {
      owner                          = "ipni"
      owner_id                       = "115147265"
      repo_name                      = "cidstats"
      repo_id                        = "1431165956"
      production_branch              = "main"
      production_deployments_enabled = true
      pr_comments_enabled            = true
      preview_deployment_setting     = "all"
      preview_branch_includes        = ["*"]
      path_includes                  = ["*"]
    }
  }
}

resource "cloudflare_pages_domain" "cidstats" {
  count = local.cidstats_cutover ? 1 : 0

  account_id   = local.account_id
  project_name = cloudflare_pages_project.cidstats.name
  name         = "cidstats.ipni.io"
}
