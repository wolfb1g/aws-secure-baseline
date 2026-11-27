locals {
  cloudtrail_name       = "${var.environment}-management-trail"
  cloudtrail_arn        = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
  cloudtrail_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.cloudtrail_bucket_name}"
}

module "cloudtrail_logs" {
  source = "../../modules/secure-s3-bucket"

  bucket_name            = var.cloudtrail_bucket_name
  access_log_bucket_name = var.access_log_bucket_name

  bucket_policy_statements = [
    {
      sid    = "AllowCloudTrailAclCheck"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      actions   = ["s3:GetBucketAcl"]
      resources = [local.cloudtrail_bucket_arn]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values   = [local.cloudtrail_arn]
        }
      ]
    },
    {
      sid    = "AllowCloudTrailWrite"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      actions   = ["s3:PutObject"]
      resources = ["${local.cloudtrail_bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "s3:x-amz-acl"
          values   = ["bucket-owner-full-control"]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values   = [local.cloudtrail_arn]
        }
      ]
    }
  ]

  kms_key_policy_statements = [
    {
      sid    = "AllowCloudTrailGenerateDataKey"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      actions = ["kms:GenerateDataKey*"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values   = [local.cloudtrail_arn]
        },
        {
          test     = "StringLike"
          variable = "kms:EncryptionContext:aws:cloudtrail:arn"
          values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
        }
      ]
    },
    {
      sid    = "AllowCloudTrailDescribeKey"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      actions = ["kms:DescribeKey"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values   = [local.cloudtrail_arn]
        }
      ]
    },
    {
      # The module enables S3 Bucket Keys. With a Bucket Key on the destination bucket,
      # CloudTrail requires kms:Decrypt to create or update a trail that uses SSE-KMS.
      sid    = "AllowCloudTrailDecrypt"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      actions = ["kms:Decrypt"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values   = [local.cloudtrail_arn]
        }
      ]
    },
    {
      sid    = "AllowAccountDecryptCloudTrailLogs"
      effect = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
      ]
      # kms:DescribeKey is omitted: it carries no encryption context, so the
      # aws:cloudtrail:arn condition below could never match it.
      actions = ["kms:Decrypt"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "StringLike"
          variable = "kms:EncryptionContext:aws:cloudtrail:arn"
          values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
        }
      ]
    }
  ]
}

resource "aws_cloudtrail" "this" {
  #checkov:skip=CKV_AWS_252:SNS topic notifications for CloudTrail log delivery are out of scope per docs/PROJECT_BRIEF.md Section 3.
  #checkov:skip=CKV2_AWS_10:CloudWatch Logs integration is out of scope per docs/PROJECT_BRIEF.md Section 3 to avoid ongoing log ingestion and storage costs; management events are stored in KMS-encrypted S3 with log file validation.
  name                          = local.cloudtrail_name
  s3_bucket_name                = module.cloudtrail_logs.bucket_id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  kms_key_id                    = module.cloudtrail_logs.kms_key_arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [module.cloudtrail_logs]
}
