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
  description = "Environment name used to label resources through default tags."
  type        = string
  default     = "dev"
}
