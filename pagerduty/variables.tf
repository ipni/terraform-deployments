variable "members" {
  description = <<-EOT
    PagerDuty users, keyed by a short public alias (their GitHub handle): the
    keys show in plans, the values don't. CI sets TF_VAR_members from the
    PAGERDUTY_MEMBERS secret, one-line JSON:
    {"<alias>": {"id": "P…", "name": "…", "email": "…", "role": "owner|admin|user|limited_user"}}
    id imports an existing user; leave it out to create (and invite) a new one.
    on_call (default true) puts them in the weekly rotation.
  EOT
  type = map(object({
    id      = optional(string)
    name    = string
    email   = string
    role    = string
    on_call = optional(bool, true)
  }))
  sensitive = true
}
