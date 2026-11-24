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
