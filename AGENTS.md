# Contributor and agent rules

- Use English for all code, comments, documentation, commit messages, and PRs.
- No AWS credentials exist in the development environment. NEVER run `terraform plan`, `terraform apply`, or `terraform destroy`; never call AWS APIs, including through the AWS CLI or SDKs.
- Before every commit, run `terraform fmt -recursive`, `terraform -chdir=environments/dev init -backend=false`, `terraform -chdir=environments/dev validate`, `checkov -d . --quiet --compact`, and `gitleaks dir .` locally. Check formatting with `terraform fmt -check -recursive` before submitting the change.
- Never commit secrets, AWS account IDs, ARNs containing real account numbers, or Terraform state files. Use variables and placeholders for deployment-specific values.
- Keep each PR focused on one security control. Open PRs as drafts and stack them when they depend on earlier changes.
- Every PR description must include these sections: **What**, **Why**, **How to test**, and **Security considerations**.
- Use Conventional Commits (for example, `chore: initialize repository foundation`).
- Every skipped Checkov check requires an inline justification using `#checkov:skip=CKV_...:reason` with the actual check ID and a specific reason.
- Pin Terraform versions with an explicit version constraint, constrain provider versions, and commit `.terraform.lock.hcl`. Pin GitHub Actions to full commit SHAs when workflows are added.
- If blocked, document the blocker in the PR and continue with independent work that remains within these rules.
