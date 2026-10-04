output "bucket_id" {
  description = "Name and ID of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Global DNS domain name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional DNS domain name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS encryption key."
  value       = aws_kms_key.this.arn
}

output "kms_key_id" {
  description = "ID of the customer-managed KMS encryption key."
  value       = aws_kms_key.this.key_id
}

output "kms_alias_arn" {
  description = "ARN of the bucket-specific KMS key alias."
  value       = aws_kms_alias.this.arn
}
