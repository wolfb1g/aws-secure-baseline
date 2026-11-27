variable "aws_region" {
  description = "AWS region in which regional security controls will be deployed."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "The AWS region must use a region identifier format, such as us-east-1 or us-gov-west-1."
  }
}

variable "environment" {
  description = "Environment name used to name resources and label them through default tags."
  type        = string
  default     = "dev"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.environment))
    error_message = "The environment name must be non-empty and use only lowercase alphanumeric characters and single hyphens."
  }
}

variable "budget_monthly_limit_usd" {
  description = "Monthly AWS cost budget limit in USD."
  type        = number
  default     = 10
  nullable    = false

  validation {
    condition     = var.budget_monthly_limit_usd > 0
    error_message = "The monthly budget limit must be greater than zero."
  }
}

variable "budget_alert_email" {
  description = "Recipient email address for AWS Budget threshold alerts. Supply this in a gitignored terraform.tfvars file at deployment time; never commit it."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", var.budget_alert_email))
    error_message = "The budget alert email must contain a local part, domain, and top-level domain without whitespace."
  }
}

variable "access_log_bucket_name" {
  description = "Existing, separate SSE-S3 server-access-log destination bucket in the same account and Region, with log-delivery permissions. Supply this in a gitignored terraform.tfvars file at deployment time."
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
}

variable "cloudtrail_bucket_name" {
  description = "Globally unique general-purpose S3 bucket name for CloudTrail logs in the shared namespace. Supply this in a gitignored terraform.tfvars file at deployment time."
  type        = string
  nullable    = false

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.cloudtrail_bucket_name)) &&
      !strcontains(var.cloudtrail_bucket_name, "..") &&
      !can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}$", var.cloudtrail_bucket_name)) &&
      !can(regex("^(xn--|sthree-|amzn-s3-demo-)", var.cloudtrail_bucket_name)) &&
      !can(regex("(-s3alias|--ol-s3|\\.mrap|--x-s3|--table-s3|-an)$", var.cloudtrail_bucket_name))
    )
    error_message = "Use 3-63 lowercase letters, digits, dots, or hyphens, beginning and ending with a letter or digit, without adjacent dots, an IP address, or an AWS-reserved prefix/suffix."
  }

  validation {
    condition     = !strcontains(var.cloudtrail_bucket_name, ".")
    error_message = "The CloudTrail bucket name must not contain dots because the secure-s3-bucket module creates an exact alias/<bucket_name> KMS alias."
  }

  validation {
    condition     = var.cloudtrail_bucket_name != var.access_log_bucket_name
    error_message = "The CloudTrail logs bucket must differ from the access-log destination bucket to avoid recursive logging."
  }
}

variable "config_bucket_name" {
  description = "Globally unique general-purpose S3 bucket name for AWS Config configuration history and snapshots in the shared namespace. Supply this in a gitignored terraform.tfvars file at deployment time."
  type        = string
  nullable    = false

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.config_bucket_name)) &&
      !strcontains(var.config_bucket_name, "..") &&
      !can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}$", var.config_bucket_name)) &&
      !can(regex("^(xn--|sthree-|amzn-s3-demo-)", var.config_bucket_name)) &&
      !can(regex("(-s3alias|--ol-s3|\\.mrap|--x-s3|--table-s3|-an)$", var.config_bucket_name))
    )
    error_message = "Use 3-63 lowercase letters, digits, dots, or hyphens, beginning and ending with a letter or digit, without adjacent dots, an IP address, or an AWS-reserved prefix/suffix."
  }

  validation {
    condition     = !strcontains(var.config_bucket_name, ".")
    error_message = "The AWS Config bucket name must not contain dots because the secure-s3-bucket module creates an exact alias/<bucket_name> KMS alias."
  }

  validation {
    condition     = var.config_bucket_name != var.access_log_bucket_name
    error_message = "The AWS Config logs bucket must differ from the access-log destination bucket to avoid recursive logging."
  }

  validation {
    condition     = var.config_bucket_name != var.cloudtrail_bucket_name
    error_message = "The AWS Config logs bucket must differ from the CloudTrail logs bucket so each control writes to its own dedicated bucket."
  }
}

variable "config_create_service_linked_role" {
  description = "Whether Terraform creates the account-wide AWSServiceRoleForConfig service-linked role for AWS Config. Enabled by default; set to false if the account already has AWSServiceRoleForConfig from prior AWS Config usage."
  type        = bool
  default     = true
  nullable    = false
}

variable "guardduty_enable_eks_audit_logs" {
  description = "Whether to enable GuardDuty EKS Audit Log Monitoring. Disabled by default to avoid per-event Kubernetes audit log analysis charges after the 30-day free trial."
  type        = bool
  default     = false
  nullable    = false
}

variable "guardduty_enable_ebs_malware_protection" {
  description = "Whether to enable GuardDuty Malware Protection for EC2 (EBS volume scanning on suspicious activity). Disabled by default to avoid per-GB EBS scan charges after the 30-day free trial."
  type        = bool
  default     = false
  nullable    = false
}

variable "guardduty_enable_rds_login_events" {
  description = "Whether to enable GuardDuty RDS Protection for Aurora and RDS login activity. Disabled by default to avoid vCPU-based RDS protection charges after the 30-day free trial."
  type        = bool
  default     = false
  nullable    = false
}

variable "guardduty_enable_lambda_network_logs" {
  description = "Whether to enable GuardDuty Lambda Protection for serverless network activity logs. Disabled by default to avoid VPC flow and Lambda network log volume charges after the 30-day free trial."
  type        = bool
  default     = false
  nullable    = false
}

variable "guardduty_enable_runtime_monitoring" {
  description = "Whether to enable GuardDuty Runtime Monitoring across supported compute workloads (ECS, EKS, and EC2). Disabled by default to avoid vCPU- and memory-based runtime monitoring charges after the 30-day free trial."
  type        = bool
  default     = false
  nullable    = false
}

variable "guardduty_enable_ai_protection" {
  description = "Whether to enable GuardDuty AI Protection (analysis of CloudTrail data events from AI workloads). Disabled by default because new detectors otherwise enable it automatically and it is billed per GB analyzed after the 30-day free trial."
  type        = bool
  default     = false
  nullable    = false
}

variable "securityhub_cis_version" {
  description = "Version of the CIS AWS Foundations Benchmark standard enabled in AWS Security Hub; defaults to 5.0.0, the latest version Security Hub supports."
  type        = string
  default     = "5.0.0"
  nullable    = false

  validation {
    condition     = contains(["1.2.0", "1.4.0", "3.0.0", "5.0.0"], var.securityhub_cis_version)
    error_message = "The CIS AWS Foundations Benchmark version must be one of 1.2.0, 1.4.0, 3.0.0, or 5.0.0."
  }
}
