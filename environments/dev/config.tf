resource "aws_iam_service_linked_role" "config" {
  count            = var.config_create_service_linked_role ? 1 : 0
  aws_service_name = "config.amazonaws.com"
}

locals {
  config_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.config_bucket_name}"
  config_slr_arn    = var.config_create_service_linked_role ? aws_iam_service_linked_role.config[0].arn : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
}

module "config_logs" {
  source = "../../modules/secure-s3-bucket"

  bucket_name            = var.config_bucket_name
  access_log_bucket_name = var.access_log_bucket_name

  bucket_policy_statements = [
    {
      sid    = "AllowAWSConfigBucketPermissionsCheck"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["config.amazonaws.com"]
        }
      ]
      actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
      resources = [local.config_bucket_arn]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    },
    {
      sid    = "AllowAWSConfigBucketDelivery"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["config.amazonaws.com"]
        }
      ]
      actions   = ["s3:PutObject"]
      resources = ["${local.config_bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "s3:x-amz-acl"
          values   = ["bucket-owner-full-control"]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]

  kms_key_policy_statements = [
    {
      sid    = "AllowAWSConfigServiceKMS"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["config.amazonaws.com"]
        }
      ]
      actions = ["kms:Decrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    },
    {
      sid    = "AllowAWSConfigServiceLinkedRoleKMS"
      effect = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = [local.config_slr_arn]
        }
      ]
      actions = ["kms:Decrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:s3:arn"
          values   = [local.config_bucket_arn, "${local.config_bucket_arn}/*"]
        }
      ]
    }
  ]
}

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.environment}-recorder"
  role_arn = local.config_slr_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  recording_mode {
    recording_frequency = "DAILY"
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "${var.environment}-delivery-channel"
  s3_bucket_name = module.config_logs.bucket_id
  s3_kms_key_arn = module.config_logs.kms_key_arn

  depends_on = [aws_config_configuration_recorder.this, module.config_logs]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
