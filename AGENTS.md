# Contributor and agent rules

This file is the single source of truth for how humans and AI agents work in this repository. These rules apply regardless of the tool, editor, model, or agent used. Tool-specific configuration files must defer to this file and must not contradict it.

## General

- Use English for all code, comments, documentation, commit messages, and PRs.
- If blocked, document the blocker in the PR and continue with independent work that remains within these rules.

## Terraform and local checks

- Pin Terraform versions with an explicit version constraint, constrain provider versions, and commit `.terraform.lock.hcl`. Pin GitHub Actions to full commit SHAs when workflows are added.
- Before every commit, run `terraform fmt -recursive`, `terraform -chdir=environments/dev init -backend=false`, `terraform -chdir=environments/dev validate`, `checkov -d . --quiet --compact`, and `gitleaks dir .` locally. Check formatting with `terraform fmt -check -recursive` before submitting the change.

## Git and commits

- Use Conventional Commits in English (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`), for example `chore: initialize repository foundation`.
- Never commit directly to `main`. Use one branch and one PR per security control.
- Do NOT stack PRs. Open the next PR only after the previous one is merged.
- Never use `--no-verify`, never disable or skip hooks, and never force-push to `main`.
- If a commit or push fails, fix the root cause.

## Pull requests

- Keep each PR focused on one security control.
- Open PRs as drafts.
- Every PR description must include these sections: **What**, **Why**, **How to test**, and **Security considerations**. Follow `.github/pull_request_template.md`.
- Never skip, disable, or weaken tests or checks (`terraform fmt`, `terraform validate`, Checkov, Gitleaks) to make them pass.
- Every skipped Checkov check requires an inline justification using `#checkov:skip=CKV_...:reason` with the actual check ID and a specific reason.
- When resolving conflicts, preserve the intent of both sides and explain any discarded change in the PR.
- When addressing review comments, answer each one; if you disagree, explain why.

## Secrets

- Never commit secrets, AWS account IDs, ARNs containing real account numbers, or Terraform state files. Use variables and placeholders for deployment-specific values.
- If a push or scan is blocked because of a secret, remove it from the code AND from git history, report it in the PR, and never bypass secret scanning.

## AWS

- Agents never receive AWS credentials, and no AWS credentials exist in the development environment.
- NEVER run `terraform plan`, `terraform apply`, or `terraform destroy`; never call AWS APIs, including through the AWS CLI or SDKs.
- The human maintainer runs `terraform plan`, `terraform apply`, and `terraform destroy`.

## Multi-agent work

- Work is split between two roles:
  - **Coordinator**: plans the work, delegates implementation, reviews results, and owns commits and PRs.
  - **Implementer**: carries out delegated implementation work and returns the changes to the coordinator.
- The coordinator reviews every delegated diff before committing.
- Implementers follow every rule in this file, the same as the coordinator.
- Example setup: Claude acts as the coordinator and delegates implementation to Grok through a delegation tool such as `delegate_task`. Any agent or tool that fills these roles works the same way.
