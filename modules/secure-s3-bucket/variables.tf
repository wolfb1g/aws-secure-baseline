variable "bucket_name" {
  description = "Globally unique name of the general-purpose S3 bucket in the shared namespace."
  type        = string
  nullable    = false

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name)) &&
      !strcontains(var.bucket_name, "..") &&
      !can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}$", var.bucket_name)) &&
      !can(regex("^(xn--|sthree-|amzn-s3-demo-)", var.bucket_name)) &&
      !can(regex("(-s3alias|--ol-s3|\\.mrap|--x-s3|--table-s3|-an)$", var.bucket_name))
    )
    error_message = "Use 3-63 lowercase letters, digits, dots, or hyphens, beginning and ending with a letter or digit, without adjacent dots, an IP address, or an AWS-reserved prefix/suffix."
  }

  validation {
    condition     = !strcontains(var.bucket_name, ".")
    error_message = "This module requires a bucket name without dots because its exact alias/<bucket_name> KMS alias cannot contain dots."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to delete all objects and versions when destroying the bucket."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Tags for the bucket and KMS key; caller values override the module Name and ManagedBy tags."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "deletion_window_in_days" {
  description = "Waiting period before the KMS key is permanently deleted after scheduled deletion."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30 && floor(var.deletion_window_in_days) == var.deletion_window_in_days
    error_message = "The KMS deletion window must be an integer between 7 and 30 days."
  }
}

variable "kms_key_additional_principal_arns" {
  description = "Additional IAM role or user ARNs allowed to use this key through regional S3 for this bucket; grants no S3 permissions."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for arn in var.kms_key_additional_principal_arns :
      can(regex("^arn:[a-z0-9-]+:iam::[0-9]{12}:(role|user)/[A-Za-z0-9+=,.@_/-]+$", arn))
    ])
    error_message = "Additional principals must be explicit IAM role or user ARNs, without wildcards."
  }
}

variable "access_log_bucket_name" {
  description = "Existing, separate access-log destination bucket in the same account and Region, with log-delivery permissions."
  type        = string
  nullable    = false

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.access_log_bucket_name)) &&
      !strcontains(var.access_log_bucket_name, "..") &&
      !can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}$", var.access_log_bucket_name)) &&
      !can(regex("^(xn--|sthree-|amzn-s3-demo-)", var.access_log_bucket_name)) &&
      !can(regex("(-s3alias|--ol-s3|\\.mrap|--x-s3|--table-s3)$", var.access_log_bucket_name))
    )
    error_message = "The log destination must be a valid general-purpose S3 bucket name."
  }

  validation {
    condition     = var.access_log_bucket_name != var.bucket_name
    error_message = "The access-log bucket must differ from the source bucket to avoid recursive logging."
  }
}

variable "access_log_prefix" {
  description = "Prefix for server access logs; null defaults to <bucket_name>/ and an empty string writes at the target root."
  type        = string
  default     = null
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days after initiation before incomplete multipart uploads are aborted."
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.abort_incomplete_multipart_upload_days >= 1 && floor(var.abort_incomplete_multipart_upload_days) == var.abort_incomplete_multipart_upload_days
    error_message = "Multipart upload cleanup must be a positive integer number of days."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Days before noncurrent object versions are permanently deleted; null or zero disables expiration."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days == null ? true : var.noncurrent_version_expiration_days >= 0 && floor(var.noncurrent_version_expiration_days) == var.noncurrent_version_expiration_days
    error_message = "Noncurrent version expiration must be null or a nonnegative integer number of days."
  }
}
