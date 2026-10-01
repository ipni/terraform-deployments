resource "cloudflare_pages_domain" "this" {
  account_id   = var.account_id
  project_name = var.pages_project
  name         = var.zone_name
}
