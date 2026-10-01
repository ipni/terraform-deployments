variable "alert_emails" {
  description = "Email addresses that receive the Service Worker Gateway alerts. CI sets TF_VAR_alert_emails from the SWG_ALERT_EMAILS secret."
  type        = list(string)
  sensitive   = true
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook posting to #ipni-alerts. Secret: set TF_VAR_slack_webhook_url, never commit it. Empty disables Slack."
  type        = string
  default     = ""
  sensitive   = true
}
