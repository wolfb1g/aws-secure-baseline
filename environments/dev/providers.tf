terraform {
  required_version = "~> 1.16.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "local" {}

  # Future remote-state example: replace the local backend only after provisioning
  # and securing the state bucket separately. Do not enable this in local checks.
  # backend "s3" {
  #   bucket       = "<state-bucket-name>"
  #   key          = "<state-key>"
  #   region       = "<aws-region>"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-secure-baseline"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
