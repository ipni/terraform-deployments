# The cidstats site (github.com/ipni/cidstats), mirrored from the Pages
# project of the same name in Alex@ipfs.io's Account. Project settings only:
# Pages builds and deploys the site itself on every push to the repo.
#
# Not created until the cutover. A GitHub repository can only be connected to
# Pages projects in one Cloudflare account, so Cloudflare refuses this project
# (error 8000093) while the old one exists. A project without the repository
# is no way around it: a direct-upload project can't be connected to Git later.
#
# Until then, cidstats.ipni.io points at the old project's cidstats.pages.dev,
# as in the old zone. At the cutover, after the registrar transfer:
#   1. delete the old project in Alex@ipfs.io's Account (cidstats.ipni.io is
#      down until step 2 is applied);
#   2. set cidstats_cutover to true: this creates the project, connected to the
#      repository, with cidstats.ipni.io as its custom domain, and points the
#      CNAME at it. Its pages.dev name is cidstats.pages.dev again if Cloudflare
#      has freed it, else a generated one.

locals {
  cidstats_cutover = false

  cidstats_deployment_config = {
    always_use_latest_compatibility_date = false
    build_image_major_version            = 3
    compatibility_date                   = "2026-10-23"
    # Not computed by the provider: left out, the API's [] would show as a diff.
    compatibility_flags = []
    fail_open           = true
  }
}

resource "cloudflare_pages_project" "cidstats" {
  count = local.cidstats_cutover ? 1 : 0

  account_id        = local.account_id
  name              = "cidstats"
  production_branch = "main"

  # Static files from the repo root, no build step.
  build_config = {
    build_command   = ""
    destination_dir = ""
    root_dir        = ""
  }

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
  project_name = cloudflare_pages_project.cidstats[0].name
  name         = "cidstats.ipni.io"
}
