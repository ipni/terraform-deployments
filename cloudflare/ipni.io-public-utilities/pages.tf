# The cidstats site (github.com/ipni/cidstats), mirrored from the Pages
# project of the same name in Alex@ipfs.io's Account. Project settings only:
# Pages builds and deploys the site itself on every push to the repo.
#
# Before the first apply, the Cloudflare Pages GitHub app must be installed on
# the ipni GitHub org and connected to IPFS Public Utilities (dashboard:
# Workers & Pages > Create > Pages > Connect to Git). Only the ipfs and
# ipshipyard orgs are connected there today, and Terraform cannot do it.
#
# The name `cidstats.pages.dev` belongs to the old project, so this one gets
# a generated one (`cidstats-<random>.pages.dev`); the CNAME in dns.tf follows
# it. It is only the CNAME target: people use cidstats.ipni.io.

locals {
  # Off until the cutover: cidstats.ipni.io is a custom domain of the old
  # project, and a hostname can only belong to one project. At the registrar
  # transfer: remove it from the old project, then set this to true.
  cidstats_custom_domain = false

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
      # The old project already comments on every PR; turn this on when it is
      # deleted, so PRs don't get two comments.
      pr_comments_enabled        = false
      preview_deployment_setting = "all"
      preview_branch_includes    = ["*"]
      path_includes              = ["*"]
    }
  }
}

resource "cloudflare_pages_domain" "cidstats" {
  count = local.cidstats_custom_domain ? 1 : 0

  account_id   = local.account_id
  project_name = cloudflare_pages_project.cidstats.name
  name         = "cidstats.ipni.io"
}
