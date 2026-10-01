# Project settings only. Deployments (the site content) come from the
# ipfs/service-worker-gateway repo via `wrangler pages deploy`.
# It serves both zones: inbrowser.link (production) and inbrowser.dev
# (staging, the `staging` branch), so it is managed only here.
resource "cloudflare_pages_project" "service_worker_gateway" {
  account_id        = local.account_id
  name              = "ipfs-service-worker-gateway"
  production_branch = "production"

  build_config = {
    build_caching   = false
    build_command   = ""
    destination_dir = "dist"
    root_dir        = ""
  }

  deployment_configs = {
    preview = {
      always_use_latest_compatibility_date = false
      build_image_major_version            = 2
      compatibility_date                   = "2024-05-09"
      fail_open                            = true
    }
    production = {
      always_use_latest_compatibility_date = false
      build_image_major_version            = 2
      compatibility_date                   = "2024-05-09"
      fail_open                            = true
    }
  }

  source = {
    type = "github"
    config = {
      owner                          = "ipfs"
      owner_id                       = "10536621"
      repo_name                      = "service-worker-gateway"
      repo_id                        = "621947766"
      production_branch              = "production"
      production_deployments_enabled = true
      pr_comments_enabled            = false
      preview_deployment_setting     = "custom"
      preview_branch_includes        = ["staging"]
      path_includes                  = ["*"]
    }
  }
}
