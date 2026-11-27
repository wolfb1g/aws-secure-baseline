# =============================================================================
# PIPELINE DEMO: DELIBERATELY INSECURE. DO NOT MERGE. DO NOT APPLY.
# =============================================================================
# This file exists only on the draft PR "demo: insecure public S3 bucket blocked
# by CI (DO NOT MERGE)". It shows that the Checkov job in CI fails a pull request
# that proposes an S3 bucket open to the public and without encryption.
#
# It is not a Terraform root used for deployment: it is never initialized,
# planned, or applied, and the bucket name is a placeholder. The secure
# equivalent is modules/secure-s3-bucket.
# =============================================================================

# INSECURE: no default encryption configuration (no
# aws_s3_bucket_server_side_encryption_configuration with a KMS key), no
# versioning, no server access logging, and no lifecycle rules.
resource "aws_s3_bucket" "insecure_demo" {
  bucket = "example-insecure-public-demo-bucket"
}

# INSECURE: all four bucket-level Block Public Access settings are turned off,
# so public ACLs and public bucket policies would take effect.
resource "aws_s3_bucket_public_access_block" "insecure_demo" {
  bucket = aws_s3_bucket.insecure_demo.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# INSECURE: bucket policy that lets anyone on the internet read every object.
resource "aws_s3_bucket_policy" "insecure_demo" {
  bucket = aws_s3_bucket.insecure_demo.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForDemoOnly"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.insecure_demo.arn}/*"
      }
    ]
  })
}
