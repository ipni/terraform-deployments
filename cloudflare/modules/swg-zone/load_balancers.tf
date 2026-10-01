# Subdomain gateways (*.ipfs / *.ipns), served by the Pages and Rainbow pools.
resource "cloudflare_load_balancer" "gateway" {
  for_each = var.load_balancers

  zone_id              = var.zone_id
  name                 = "*.${each.key}.${var.zone_name}"
  description          = local.managed_by
  default_pools        = each.value.pools
  fallback_pool        = each.value.fallback
  enabled              = true
  proxied              = true
  networks             = ["cloudflare"]
  steering_policy      = "off" # pools are tried in order (failover)
  session_affinity     = "ip_cookie"
  session_affinity_ttl = 82800
  pop_pools            = {}
  region_pools         = {}

  adaptive_routing = {
    failover_across_pools = false
  }
  location_strategy = {
    mode       = "pop"
    prefer_ecs = "proximity"
  }
  random_steering = {
    default_weight = 1
  }
  session_affinity_attributes = {
    drain_duration         = 0
    samesite               = "Auto"
    secure                 = "Auto"
    zero_downtime_failover = "none"
  }
}
