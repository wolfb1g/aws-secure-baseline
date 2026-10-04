# aws-secure-baseline

[![CI](https://github.com/wolfb1g/aws-secure-baseline/actions/workflows/ci.yml/badge.svg)](https://github.com/wolfb1g/aws-secure-baseline/actions)

[![CI](https://github.com/wolfb1g/aws-secure-baseline/actions/workflows/ci.yml/badge.svg)](https://github.com/wolfb1g/aws-secure-baseline/actions)

[![CI](https://github.com/wolfb1g/aws-secure-baseline/actions/workflows/ci.yml/badge.svg)](https://github.com/wolfb1g/aws-secure-baseline/actions/workflows/ci.yml)

A Terraform security baseline for an AWS account, built as a Cloud Security portfolio project. The goal is to demonstrate repeatable security controls, least-privilege design, and verifiable infrastructure changes through small, reviewable PRs.

## Planned controls

| Control | Purpose | Status |
| --- | --- | --- |
| CloudTrail | Record account activity for auditing and investigation | Planned |
| GuardDuty | Detect suspicious activity and potential threats | Planned |
| Security Hub + CIS AWS Foundations | Aggregate findings and assess the account against the CIS AWS Foundations standard | Planned |
| Account-level S3 Block Public Access | Prevent public access to S3 at the account boundary | Planned |
| IAM password policy | Establish requirements for IAM user passwords | Planned |
| Reusable secure S3 bucket module | Provide consistent bucket encryption, access restrictions, and secure defaults | Implemented (module) |
| AWS Budget | Track spending against an explicit budget and alert on thresholds | Planned |

## Repository layout

```text
.
├── .github/workflows/ci.yml         # Credential-free validation and security checks
├── modules/
│   └── secure-s3-bucket/            # Private, KMS-encrypted S3 bucket with secure defaults
├── environments/
│   └── dev/
│       ├── .terraform.lock.hcl     # Committed provider version and checksums
│       ├── providers.tf            # Terraform, provider, backend, and tags
│       ├── variables.tf            # Region and environment inputs
│       ├── main.tf                 # Future control wiring; no resources yet
│       └── terraform.tfvars.example
├── .gitignore
├── AGENTS.md                       # Contributor and agent rules
└── README.md
```

## Prerequisites

- Terraform `~> 1.16.4` (at least 1.16.4 and below 1.17.0).
- HashiCorp AWS provider `~> 6.0` (6.x), installed by `terraform init`; the committed lock file records the selected version.
- Checkov `3.3.20` and Gitleaks `8.30.1` installed locally to match CI.
- Network access to the Terraform Registry and provider distribution endpoints for initialization.

AWS credentials are not available in the development environment and are not needed for the static checks below.

## Quick start

Run from the repository root:

```sh
terraform fmt -check -recursive
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate
```

Initialization downloads providers without initializing a state backend. Validation checks configuration syntax and provider schemas without calling AWS APIs. These commands do not provision resources.

`plan` and `apply` require AWS credentials and are out of scope for CI. Contributor and agent rules prohibit running `plan`, `apply`, or `destroy` in the development environment and prohibit calling AWS APIs.

The example variables file contains placeholders only. Static checks use the defaults (`us-east-1` and `dev`); deployment-specific values belong in an ignored local `terraform.tfvars` file when deployment is authorized.

## Security principles

- Keep secrets, AWS account IDs, real-account ARNs, and Terraform state out of version control.
- Use variables and placeholders for deployment-specific data; never embed credentials.
- Design each control with least privilege and a documented security rationale.
- Commit `.terraform.lock.hcl` and constrain Terraform and provider versions for reproducible checks.
- Keep downloaded providers and local configuration ignored by Git.
- Use a local backend for this foundation. The commented [S3 backend example](https://developer.hashicorp.com/terraform/language/backend/s3) is a future option with encryption and native state locking; it must remain disabled during static checks.

## Continuous integration

The [CI workflow](.github/workflows/ci.yml) runs on pull requests targeting any branch, including stacked PRs, and on pushes to `main`. Three independent jobs fail on formatting errors, invalid Terraform, security findings, or detected secrets:

- **Terraform:** Terraform `1.16.4` checks formatting recursively, then initializes with `-backend=false -input=false` and validates every directory containing `.tf` files under `environments/` and `modules/`. Downloaded `.terraform/` directories are excluded; future roots and modules are discovered automatically.
- **Checkov:** Checkov `3.3.20` scans the whole repository for Terraform and GitHub Actions findings, with soft failure explicitly disabled. Any resource-specific exceptions require inline justifications and documentation in the relevant module README.
- **Gitleaks:** Gitleaks `8.30.1` scans the complete Git history with redacted output. Its release archive is verified against the release's SHA256 checksums before extraction; no Gitleaks action license is required.

Every action is pinned to a full commit SHA with its release tag recorded inline. Jobs have timeouts, the workflow grants only `contents: read`, checkout does not persist credentials, and newer runs cancel earlier runs for the same ref. The workflow needs no AWS credentials and does not authenticate to or call AWS.

To reproduce the CI checks locally with the versions above, run from the repository root:

```sh
terraform fmt -check -recursive
while IFS= read -r directory; do
  terraform -chdir="$directory" init -backend=false -input=false || exit
  terraform -chdir="$directory" validate || exit
done < <(
  find environments modules -type d -name .terraform -prune -o \
    -type f -name '*.tf' -exec dirname {} \; | sort -u
)
checkov -d . --framework terraform,github_actions --quiet --compact
gitleaks git --redact --verbose .
gitleaks dir --redact .
```

Use Bash for the loop. The additional directory scan checks uncommitted files before a commit; CI's Git scan covers committed history. Passing CI verifies these static checks, not deployed AWS controls or account compliance.

## Roadmap and current status

The repository foundation is in place: provider configuration, validated inputs, default tags, a dependency lock file, and contributor rules. The [secure S3 bucket module](modules/secure-s3-bucket/README.md) defines a reusable control but is not wired into `environments/dev`; no AWS resources have been deployed. Static checks do not establish that an AWS account meets any security standard.

Credential-free CI is implemented for formatting, validation, Checkov, and Gitleaks, with GitHub Actions pinned to full commit SHAs. Next, implement the planned controls one per draft PR, stacking dependent PRs, with test instructions and security considerations in every description.
