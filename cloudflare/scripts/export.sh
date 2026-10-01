#!/usr/bin/env bash
# Exports the existing Cloudflare config for a zone to Terraform.
# Writes <type>.tf and <type>_imports.tf per resource type into generated/.
# Read-only: it only calls the Cloudflare API with GET requests.
#
# Output is a starting point: review it and copy what is needed into the stack.
#
# Usage: scripts/export.sh [-z zone_name] [resource_type ...]   (default zone: inbrowser.link)
set -euo pipefail

cd "$(dirname "$0")"

ZONE_NAME="inbrowser.link"
if [[ "${1:-}" == "-z" ]]; then ZONE_NAME="$2"; shift 2; fi
OUT="generated/$ZONE_NAME"

export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-$(security find-generic-password -s cloudflare-api-token -w)}"
ZONE_ID="$(curl -sf -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"][0]["id"])')"
# Zone settings changed from their defaults (cloudflare_zone_setting needs explicit IDs).
ZONE_SETTINGS="$(curl -sf -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings" \
  | python3 -c 'import sys,json; print(",".join(s["id"] for s in json.load(sys.stdin)["result"] if s.get("modified_on")))')"

TYPES=("$@")
if [[ ${#TYPES[@]} -eq 0 ]]; then
  TYPES=(
    cloudflare_dns_record
    cloudflare_ruleset
    cloudflare_zone_setting
    cloudflare_load_balancer
    cloudflare_tiered_cache
    cloudflare_zone_dnssec
  )
fi

# cf-terraforming reads the provider schema from an initialized directory.
# Use a scratch one with only versions.tf so the S3 backend isn't needed.
WORK=generated/.tfwork
mkdir -p "$WORK" "$OUT"
cp ../inbrowser.link/versions.tf "$WORK/"
[[ -d "$WORK/.terraform" ]] || terraform -chdir="$WORK" init -input=false >/dev/null
TF=(--terraform-binary-path "$(command -v terraform)" --terraform-install-path "$WORK" --zone "$ZONE_ID")

for t in "${TYPES[@]}"; do
  extra=()
  [[ "$t" == cloudflare_zone_setting ]] && extra=(--resource-id "cloudflare_zone_setting=$ZONE_SETTINGS")
  printf '%-40s' "$t"
  if cf-terraforming generate --resource-type "$t" "${TF[@]}" "${extra[@]}" \
       > "$OUT/$t.tf" 2> "$OUT/$t.err" \
     && cf-terraforming import --resource-type "$t" --modern-import-block "${TF[@]}" "${extra[@]}" \
       > "$OUT/${t}_imports.tf" 2>> "$OUT/$t.err"; then
    n=$(grep -c '^resource ' "$OUT/$t.tf" || true)
    echo "ok ($n)"
    [[ "$n" -gt 0 ]] || rm -f "$OUT/$t.tf" "$OUT/${t}_imports.tf"
    rm -f "$OUT/$t.err"
  else
    echo "FAILED (see $OUT/$t.err)"
  fi
done
