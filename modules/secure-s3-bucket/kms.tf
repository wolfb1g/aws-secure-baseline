data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  account_root_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  # KMS ViaService names use amazonaws.com in every AWS partition.
  s3_via_service = "s3.${data.aws_region.current.region}.amazonaws.com"
  kms_usage_actions = [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:DescribeKey",
  ]
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "AllowAccountKeyAdministration"
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    # In a KMS key policy, * means the key to which the policy is attached.
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.account_root_arn]
    }
  }

  statement {
    sid       = "AllowAccountUseThroughS3"
    effect    = "Allow"
    actions   = local.kms_usage_actions
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.account_root_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [local.s3_via_service]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.kms_key_additional_principal_arns) > 0 ? [1] : []
    content {
      sid       = "AllowAdditionalPrincipalsThroughS3"
      effect    = "Allow"
      actions   = local.kms_usage_actions
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.kms_key_additional_principal_arns
      }

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = [local.s3_via_service]
      }

      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values   = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "S3 encryption key for ${var.bucket_name}"
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_in_days
  policy                  = data.aws_iam_policy_document.kms.json
  tags                    = local.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.bucket_name}"
  target_key_id = aws_kms_key.this.key_id
}
