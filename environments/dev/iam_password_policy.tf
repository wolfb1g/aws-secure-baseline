resource "aws_iam_account_password_policy" "this" {
  #checkov:skip=CKV_AWS_9:NIST SP 800-63B Section 5.1.1.2 recommends against arbitrary periodic password expiration without evidence of compromise; CIS AWS Foundations v3.0.0+ removed forced 90-day rotation.
  minimum_password_length        = 14
  password_reuse_prevention      = 24
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
}
