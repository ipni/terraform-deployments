# IAM roles that the "Terraform (Cloudflare)" GitHub Actions workflow assumes
# through GitHub OIDC to reach the state bucket. Applied by hand by someone
# with IAM rights; CI never applies this stack.
#
# - plan:  pull requests and manual runs on main. Reads state, can only write
#          the lock file, so it can never change state.
# - apply: only workflow runs on main (a merged PR). Reads and writes state.
#
# Only the main branch can apply. The repo is public: pull requests from forks
# get no OIDC token, so they cannot assume either role.

terraform {
  required_version = ">= 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

locals {
  # GitHub's immutable OIDC subject for ipni/terraform-deployments:
  # owner@owner_id/repo@repo_id, so a renamed or re-created repo with the same
  # name never matches. IDs from `gh api repos/ipni/terraform-deployments`.
  repo         = "ipni@115147265/terraform-deployments@1400567172"
  state_bucket = "arn:aws:s3:::ipni-terraform-state"
  state_prefix = "cloudflare/"
}

# Created outside Terraform and shared with other ipni workflows.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "trust_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repo}:pull_request",
        "repo:${local.repo}:ref:refs/heads/main",
      ]
    }
  }
}

data "aws_iam_policy_document" "trust_apply" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repo}:ref:refs/heads/main"]
    }
  }
}

data "aws_iam_policy_document" "state_plan" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.state_prefix}*"]
    }
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${local.state_bucket}/${local.state_prefix}*"]
  }
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket}/${local.state_prefix}*.tflock"]
  }
}

data "aws_iam_policy_document" "state_apply" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.state_prefix}*"]
    }
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${local.state_bucket}/${local.state_prefix}*"]
  }
  statement {
    actions   = ["s3:DeleteObject"]
    resources = ["${local.state_bucket}/${local.state_prefix}*.tflock"]
  }
}

resource "aws_iam_role" "plan" {
  name                 = "github-terraform-cloudflare-plan"
  assume_role_policy   = data.aws_iam_policy_document.trust_plan.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "plan" {
  role   = aws_iam_role.plan.id
  name   = "terraform-state-read"
  policy = data.aws_iam_policy_document.state_plan.json
}

resource "aws_iam_role" "apply" {
  name                 = "github-terraform-cloudflare-apply"
  assume_role_policy   = data.aws_iam_policy_document.trust_apply.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "apply" {
  role   = aws_iam_role.apply.id
  name   = "terraform-state-write"
  policy = data.aws_iam_policy_document.state_apply.json
}

output "plan_role_arn" {
  value = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  value = aws_iam_role.apply.arn
}
