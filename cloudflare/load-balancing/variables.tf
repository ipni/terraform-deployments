variable "rainbow_origins" {
  description = <<-EOT
    Rainbow origins per pool, as { bhs = { <origin name> = <address> }, eri = { ... } }.
    Kept out of the repo so the origin addresses behind Cloudflare stay private:
    CI sets TF_VAR_rainbow_origins from the RAINBOW_ORIGINS secret.
  EOT
  type = object({
    bhs = map(string)
    eri = map(string)
  })
  sensitive = true
}
