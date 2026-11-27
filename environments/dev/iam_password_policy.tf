resource "aws_iam_account_password_policy" "this" {
  #checkov:skip=CKV_AWS_9:Forced periodic expiration is intentionally omitted: NIST SP 800-63B-4 Section 3.1.1.2 says verifiers SHALL NOT require periodic password changes and SHALL force a change only on evidence of compromise; CIS AWS Foundations v5.0.0 has no expiration recommendation (the 90-day check, Security Hub IAM.17, maps only to CIS v1.2.0).
  minimum_password_length        = 14
  password_reuse_prevention      = 24
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
}
