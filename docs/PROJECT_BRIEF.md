Project Brief — aws-secure-baseline

Version 1 — 2026-11-23. Read together with AGENTS.md (the single source of truth for how to work) and README.md (current state). If this brief ever conflicts with AGENTS.md, AGENTS.md wins.

1. What this project is

A Terraform security baseline for a single AWS account, built as a Cloud Security portfolio project.

It must show, through small and reviewable pull requests, that the maintainer can:

write Infrastructure as Code for security controls;
apply least privilege and secure defaults;
explain the security rationale of every control;
verify that each control actually works after deployment.

The target audience is hiring managers for Cloud Security Analyst roles (AWS IAM, CloudTrail, GuardDuty, Security Hub, Config, KMS, CIS Benchmarks, IaC).

2. Current state

Done: repository foundation (providers, validated variables, default tags, committed lock file), credential-free CI (Terraform fmt/validate, Checkov, Gitleaks, actions pinned to full SHAs), and the secure-s3-bucket module.
Not done: the module is not wired into environments/dev. None of the planned controls exist. Nothing has been deployed.
3. Scope: one pull request per item, in this order

Each PR is opened as a draft, only after the previous one is merged (no stacking).

PR	Item	What it delivers
0	Documentation fixes	Remove the duplicated CI badges from README.md (keep one). Align README.md with AGENTS.md: PRs are not stacked.
1	AWS Budget	Monthly cost budget with a variable limit and alerts at 50%, 80% and 100% (actual) plus 100% (forecasted). The alert email comes from a variable, never committed.
2	Account-level S3 Block Public Access	All four account-level settings enabled.
3	IAM password policy	CIS-aligned: minimum length 14, prevent reuse of the last 24 passwords, require upper, lower, number and symbol. No forced expiration (justify it in the PR with NIST SP 800-63B).
4	CloudTrail	Multi-region trail with global service events, log file validation and KMS encryption. Logs go to a bucket created with the secure-s3-bucket module (this wires the module in). Bucket policy grants CloudTrail only what it needs, restricted with aws:SourceArn. Management events only; data events out of scope (cost).
5	GuardDuty	Detector enabled, S3 protection enabled through the detector feature resource. Other protection plans off by default, behind variables (cost).
6	AWS Config	Recorder, delivery channel to a bucket from the secure-s3-bucket module, and the service-linked role. Use daily periodic recording to reduce cost. Required by PR 7.
7	Security Hub + CIS	Security Hub enabled with default standards off, then an explicit subscription to the CIS AWS Foundations Benchmark (latest version Security Hub supports).

Stretch, only after PR 7 is merged:

IAM Access Analyzer (external access analyzer, free).
EventBridge rule sending GuardDuty findings of high severity to an SNS email topic.

Anything else is out of scope. Do not add controls, providers or tools that are not listed here.

4. Technical guidance

Implement every control under environments/dev, calling modules where it makes sense. Create a new module only when a control is reused or clearly self-contained, and give every module a README.
If secure-s3-bucket needs extra bucket policy statements or KMS key policy statements (for CloudTrail or Config), extend the module minimally through input variables instead of duplicating it. Keep its defaults secure.
No hardcoded account IDs, ARNs with real account numbers, regions in resource names, or emails. Use variables, data sources and placeholders.
Every variable gets a description and, where possible, a validation block.
Every Checkov skip needs #checkov:skip=CKV_...:<specific reason> and a note in the relevant README.
Tags come from the provider's default tags.
5. Definition of done for every PR

[ ] CI is green: fmt, validate, Checkov and Gitleaks, with no weakened checks.
[ ] The PR description follows the template: What, Why, How to test, Security considerations.
[ ] How to test includes the human's verification steps after apply (read-only checks in the console or CLI).
[ ] The control's row in the README status table is updated.
[ ] Cost impact is stated in the PR (free, cents, trial, or monthly estimate).
[ ] Two "explain it" questions for the maintainer are listed at the end of the PR (for example: "Why is log file validation enabled?").
6. Roles

Agents (coordinator and implementer): write the code and the docs, run the local static checks, open draft PRs. They never receive AWS credentials, never call AWS APIs and never run plan, apply or destroy.
Maintainer (human): reviews every diff, answers the "explain it" questions, runs plan and apply in the lab account, verifies the control works, merges the PR.
7. Cost notes

Item	Cost
Budget, S3 Block Public Access, password policy	Free
CloudTrail	First management-events trail is free; S3 storage is cents; a customer managed KMS key is about USD 1 per month
GuardDuty	30-day free trial; the clock starts at apply
AWS Config	Charged per configuration item recorded; daily recording keeps it low
Security Hub	30-day free trial; the clock starts at apply
8. Final deliverable

When PR 7 is merged, the README is updated to a portfolio-ready state:

an architecture diagram (Mermaid) showing the controls and where logs and findings go;
the controls table with every row marked as implemented;
a "How each control is verified" section;
a cost section;
a short "Lessons learned" section written by the maintainer.
