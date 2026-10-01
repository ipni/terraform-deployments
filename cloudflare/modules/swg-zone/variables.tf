variable "account_id" {
  description = "Cloudflare account that owns the zone and the Pages project."
  type        = string
}

variable "zone_id" {
  type = string
}

variable "zone_name" {
  description = "e.g. inbrowser.link"
  type        = string
}

variable "pages_project" {
  description = "Pages project serving the zone apex."
  type        = string
}

variable "pages_target" {
  description = "Pages hostname the apex CNAME points to (production or a branch alias)."
  type        = string
}

variable "dnslink_build_cid" {
  description = "DNSLink record published at _dnslink.build-cid.<zone>."
  type = object({
    cid     = string
    comment = string
  })
}

variable "load_balancers" {
  description = "Per subdomain gateway (ipfs, ipns): pool IDs in failover order, and the fallback pool. The pools are managed in ../load-balancing."
  type = map(object({
    pools    = list(string)
    fallback = string
  }))

  validation {
    condition     = toset(keys(var.load_balancers)) == toset(["ipfs", "ipns"])
    error_message = "load_balancers must have exactly the keys ipfs and ipns."
  }
}

variable "rate_limit" {
  description = "Per-visitor rate limit on subdomain gateway requests."
  type = object({
    requests_per_period = number
    period              = number
    mitigation_timeout  = number
    message             = string
  })
}

variable "cache_rules" {
  description = "Rules for the http_request_cache_settings phase (cloudflare_ruleset rule objects)."
  type        = any
  default     = []
}

variable "extra_zone_settings" {
  description = "Zone settings on top of the shared defaults in zone_settings.tf."
  type        = map(string)
  default     = {}
}

variable "no_email_comments" {
  description = "Comments on the no-email DNS records, kept as they are in each zone."
  type = object({
    mx    = optional(string, "disable mail")
    spf   = optional(string, "disable mail")
    dkim  = optional(string, "disable email")
    dmarc = optional(string, "disable email")
  })
  default = {}
}

variable "noindex_expression" {
  description = "Override for the X-Robots-Tag rule expression (same logic, different clause order in some zones)."
  type        = string
  default     = null
}

variable "health_check_cid" {
  description = "CID probed by the zone health check at https://<cid>.ipfs.<zone>/."
  type        = string
}
