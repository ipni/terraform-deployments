# terraform-deployments

Terraform for infrastructure run by the IPNI team.

| Folder | What |
|---|---|
| [`cloudflare/`](cloudflare/README.md) | Service Worker Gateway zones (`inbrowser.link`, `inbrowser.dev`), load balancing and alerts, applied by CI on merge |
| `bootstrap/` | One-time stacks applied by hand: the S3 state bucket and the IAM roles CI assumes |

Changes go through pull requests: CI posts the plan, and merging an approved
PR applies it. See [cloudflare/README.md](cloudflare/README.md#ci).

This repo is public. Secrets and private values (origin addresses, emails,
tokens) live in repository secrets, never in the code. Report security issues
privately through GitHub's *Report a vulnerability* (Security tab), not in an
issue.

## License

Dual-licensed under [Apache-2.0 OR MIT](LICENSE.md).
