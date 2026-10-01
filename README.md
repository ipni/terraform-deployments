# terraform-deployments

Terraform for infrastructure run by the IPNI team.

| Folder | What |
|---|---|
| [`cloudflare/`](cloudflare/README.md) | Service Worker Gateway zones (`inbrowser.link`, `inbrowser.dev`), load balancing and alerts, applied by CI on merge |
| `bootstrap/` | One-time stacks applied by hand: the S3 state bucket and the IAM roles CI assumes |

Changes go through pull requests, and you don't need any credentials: CI
posts the plan on the PR, and merging it (yourself, or with auto-merge once
the checks pass) applies it and posts the result to Slack #ipni-alerts. Don't
change these resources in the Cloudflare dashboard: a nightly check reports
any difference to #ipni-alerts. See
[cloudflare/README.md](cloudflare/README.md#common-changes) for how to make
common changes.

This repo is public. Secrets and private values (origin addresses, emails,
tokens) live in repository secrets, never in the code. Report security issues
privately through GitHub's *Report a vulnerability* (Security tab), not in an
issue.

## License

Dual-licensed under [Apache-2.0 OR MIT](LICENSE.md).
