#!/usr/bin/env bash
# Posts the text on stdin (Slack mrkdwn) to the incoming webhook in
# $SLACK_WEBHOOK_URL. Does nothing if it is unset, so a missing secret never
# fails a run. Used by .github/workflows/terraform-cloudflare.yml.
set -euo pipefail

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  echo "SLACK_WEBHOOK_URL is not set; not posting to Slack."
  exit 0
fi

jq -Rsc '{text: .}' | curl -sSf -X POST -H 'Content-Type: application/json' --data @- "$SLACK_WEBHOOK_URL" >/dev/null
