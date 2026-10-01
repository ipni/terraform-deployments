output "pool_ids" {
  description = "Load balancer pool IDs, read by the zone stacks through terraform_remote_state."
  value = {
    ovh_bhs_rainbow  = cloudflare_load_balancer_pool.ovh_bhs_rainbow.id
    ovh_eri_rainbow  = cloudflare_load_balancer_pool.ovh_eri_rainbow.id
    pages_production = cloudflare_load_balancer_pool.pages_production.id
    pages_staging    = cloudflare_load_balancer_pool.pages_staging.id
  }
}
