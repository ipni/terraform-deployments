#!/usr/bin/env bash
# Prints the changes in a saved Terraform plan as sorted lines
# "<actions> <address> <sha256 of the planned values>", so two plans can be
# compared with diff. Values are hashed, never printed.
# Used by .github/workflows/terraform-cloudflare.yml.
# Usage: terraform-plan-changes.sh <planfile>   (run in the stack directory)
set -euo pipefail

sha256() { if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi; }

# An import shows as a no-op with .change.importing set: list it as "import"
# (or e.g. "import,update"), or a PR that only imports would apply nothing.
terraform show -json "$1" | jq -c '
  (.resource_changes[]?
   | select((.change.actions != ["no-op"] or .change.importing != null) and .change.actions != ["read"])
   | {k: "\([if .change.importing != null then "import" else empty end] + (.change.actions - ["no-op"]) | join(",")) \(.address)", v: .change.after}),
  ((.output_changes // {}) | to_entries[]
   | select(.value.actions != ["no-op"])
   | {k: "\(.value.actions | join(",")) output.\(.key)", v: .value.after})' |
while IFS= read -r line; do
  key=$(jq -r .k <<<"$line")
  hash=$(jq -cS .v <<<"$line" | sha256 | cut -c1-12)
  echo "$key $hash"
done | sort
