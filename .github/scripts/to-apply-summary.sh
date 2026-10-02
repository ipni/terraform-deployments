#!/usr/bin/env bash
# Prints, as Markdown, what the plans in <dir> would apply: one table per stack
# with changes, from the changes.txt files the plan job uploads
# (<dir>/plan-changes-<stack>/changes.txt). Exits 3 when no stack has changes,
# 4 when a stack has no plan, so the caller can tell those apart.
# Used by .github/workflows/terraform-cloudflare.yml.
# Usage: to-apply-summary.sh <dir> <stacks as a JSON list>
set -euo pipefail

dir=$1
stacks=$2
changed=0 missing=0 quiet=()

for stack in $(jq -r '.[]' <<<"$stacks"); do
  f="$dir/plan-changes-$stack/changes.txt"
  if [[ ! -f "$f" ]]; then
    echo "#### \`$stack\`: no plan"
    echo
    missing=1
  elif [[ -s "$f" ]]; then
    echo "#### \`$stack\`: $(wc -l <"$f" | tr -d ' ') to apply"
    echo
    echo "| Action | Address |"
    echo "|---|---|"
    # "<actions> <address> <hash>"; the hash is only for comparing plans.
    awk -v bt='`' '{
      a = $1
      sub(/^create$/, "➕ create", a); sub(/^update$/, "✏️ update", a)
      sub(/^delete$/, "➖ delete", a); sub(/^(delete,create|create,delete)$/, "♻️ replace", a)
      print "| " a " | " bt $2 bt " |"
    }' "$f"
    echo
    changed=1
  else
    quiet+=("\`$stack\`")
  fi
done

if (( ${#quiet[@]} )); then
  echo "No changes: ${quiet[*]}"
  echo
fi

(( missing )) && exit 4
(( changed )) || exit 3
exit 0
