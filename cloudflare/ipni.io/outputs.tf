output "monitoring_records" {
  description = "IPNI monitoring hostnames and whether Cloudflare proxies them."
  value       = { for name, r in cloudflare_dns_record.monitoring : name => r.proxied }
}
