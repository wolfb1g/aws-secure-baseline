# Secure S3 bucket module

Creates a private general-purpose S3 bucket with a customer-managed KMS key, versioning, access logging, transport restrictions, and lifecycle cleanup. The module inherits its AWS provider from the caller and is not wired into `environments/dev`.

## Requirements and usage

- Terraform `~> 1.16.4` and HashiCorp AWS provider `~> 6.0`.
- An existing access-log destination in the same account and Region, prepared as described below.
- A unique shared-namespace bucket name; the example names are placeholders.

Example from an environment directory such as `environments/dev`:

```hcl
module "app_data" {
  source = "../../modules/secure-s3-bucket"

  bucket_name            = "example-app-data-bucket"
  access_log_bucket_name = "example-access-logs-bucket"

  tags = {
    Project     = "aws-secure-baseline"
    Environment = "dev"
  }
}
```

The caller configures the provider Region. Account and partition information is resolved with Terraform data sources at deployment time; no account identifiers are hardcoded. Bucket names follow [AWS naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html). This module creates buckets in the shared namespace, so names ending in `-an` are rejected. It also rejects dots because the exact `alias/<bucket_name>` name must satisfy [KMS alias restrictions](https://docs.aws.amazon.com/kms/latest/APIReference/API_CreateAlias.html); existing log-destination names may contain dots.

## Security controls

References identify related controls, not proof of deployed compliance. See [AWS Security Hub S3 controls](https://docs.aws.amazon.com/securityhub/latest/userguide/s3-controls.html).

| Control | Resource | Related reference |
| --- | --- | --- |
| Customer-managed KMS default encryption and S3 Bucket Keys | `aws_kms_key.this`, `aws_s3_bucket_server_side_encryption_configuration.this` | AWS FSBP S3.17 |
| Automatic KMS rotation; explicit administration and scoped use policy | `aws_kms_key.this`, `data.aws_iam_policy_document.kms` | [AWS FSBP KMS.4](https://docs.aws.amazon.com/securityhub/latest/userguide/kms-controls.html#kms-4) (rotation) |
| Object versioning | `aws_s3_bucket_versioning.this` | AWS FSBP S3.14 |
| ACLs disabled with bucket-owner-enforced ownership | `aws_s3_bucket_ownership_controls.this` | AWS FSBP S3.12 |
| All four public-access blocks enabled | `aws_s3_bucket_public_access_block.this` | AWS FSBP S3.8 |
| Deny HTTP and TLS below 1.2 on the bucket and objects | `aws_s3_bucket_policy.this` | AWS FSBP S3.5; CIS AWS Foundations v3.0.0 2.1.1 (HTTPS) |
| Server access logging to a separate bucket | `aws_s3_bucket_logging.this` | AWS FSBP S3.9 |
| Abort incomplete uploads; expire old noncurrent versions | `aws_s3_bucket_lifecycle_configuration.this` | AWS FSBP S3.10 |
| Nonempty bucket deletion disabled by default | `aws_s3_bucket.this` | Module safeguard |

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `bucket_name` | `string` | Required | Unique bucket name, validated against shared-namespace naming restrictions; dots are disallowed for KMS alias compatibility. |
| `access_log_bucket_name` | `string` | Required | Existing log bucket, distinct from this bucket, in the same account and Region. |
| `access_log_prefix` | `string` | `null` | Null becomes `<bucket_name>/`; `""` writes logs at the destination root. |
| `force_destroy` | `bool` | `false` | Permit deletion of all objects and versions when destroying the bucket. |
| `tags` | `map(string)` | `{}` | Bucket and key tags, merged over `Name = bucket_name` and `ManagedBy = "terraform"`. |
| `deletion_window_in_days` | `number` | `30` | KMS scheduled-deletion waiting period, an integer from 7 to 30. |
| `kms_key_additional_principal_arns` | `list(string)` | `[]` | Explicit IAM user/role ARNs allowed to use this key through regional S3 for this bucket. |
| `abort_incomplete_multipart_upload_days` | `number` | `7` | Positive integer days before unfinished multipart uploads are aborted. |
| `noncurrent_version_expiration_days` | `number` | `90` | Nonnegative integer days before permanent deletion of noncurrent versions; `0` or `null` disables expiration. |

## Outputs

| Name | Description |
| --- | --- |
| `bucket_id` | Bucket name and ID. |
| `bucket_arn` | Bucket ARN. |
| `bucket_domain_name` | Global bucket DNS name. |
| `bucket_regional_domain_name` | Regional bucket DNS name. |
| `kms_key_arn` | Customer-managed key ARN. |
| `kms_key_id` | Customer-managed key ID. |
| `kms_alias_arn` | ARN of the `alias/<bucket_name>` key alias. |

## KMS and access behavior

The account root principal enables delegation of key administration through IAM. A separate statement enables account IAM principals with appropriate identity permissions to use the key through regional S3, constrained by `kms:ViaService`, `kms:CallerAccount`, and this bucket's encryption context. Additional principals receive the same S3 and encryption-context constraints, without an owner-account condition so explicit cross-account principals remain possible. These grants do not grant S3 access. See [KMS condition keys](https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html).

Both the bucket ARN (S3 Bucket Keys) and object ARNs are allowed as encryption contexts. Key policy resource `"*"` refers to the attached key, not every key in the account. Administrators can change the policy; these conditions constrain the configured use grants rather than providing immutable isolation from administrators.

Default encryption applies when clients do not select encryption themselves. This module does not deny uploads that explicitly choose another supported encryption method or key. Its bucket policy grants no application access and denies insecure transport and TLS versions below 1.2. Applications need their own least-privilege S3 and KMS permissions. Callers must not attach a competing bucket policy resource to this bucket.

## Access-log destination requirements

The log destination and its policy are not managed here. Prepare them before using this module:

- Use a separate bucket in the same account and Region, with SSE-S3 default encryption, no Object Lock/default retention, and no Requester Pays.
- Grant `logging.s3.amazonaws.com` `s3:PutObject` on the selected destination prefix through its bucket policy. Restrict delivery with `aws:SourceArn` for this source bucket and `aws:SourceAccount` for the owner account.
- Keep ACLs disabled and avoid enabling access logging on the destination itself.
- Ensure destination deny statements permit log delivery, and verify delivery after deployment.

See [AWS server access logging requirements](https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html). Because this module requires KMS encryption and logging, it is not a log-destination module. Configure destination-policy dependencies in the calling environment if Terraform manages that destination separately.

## Retention and deletion

Current objects do not expire automatically. Noncurrent versions are permanently deleted after 90 days by default; choose retention to match recovery needs or disable it with `0` or `null`. Multipart cleanup remains enabled even when noncurrent expiration is disabled. This is versioned storage, not immutable retention or cross-region disaster recovery.

`force_destroy = false` prevents Terraform from emptying a nonempty bucket, but is not a deletion lock. Scheduling deletion of its KMS key can make retained encrypted data inaccessible; the configurable waiting period defaults to 30 days. The module creates no replication destination or event consumer.

## Local validation

From the repository root, without AWS credentials:

```sh
terraform fmt -check -recursive
terraform -chdir=modules/secure-s3-bucket init -backend=false
terraform -chdir=modules/secure-s3-bucket validate
terraform -chdir=environments/dev validate
checkov -d . --framework terraform,github_actions --quiet --compact
gitleaks dir .
```

Do not run `plan`, `apply`, `destroy`, or AWS API calls in the development environment. Static checks do not verify live permissions, log delivery, globally available bucket names, or account compliance. Root configurations retain their provider lock files; the temporary lock file created by standalone module initialization is not committed.

## Checkov exceptions

The following checks are skipped inline on `aws_s3_bucket.this`; no global skips are configured:

| Check | Justification |
| --- | --- |
| `CKV_AWS_144` | Cross-region replication requires a caller-owned destination, replication role, and recovery requirements beyond this single-bucket module. |
| `CKV2_AWS_62` | Event notifications require workload-specific consumers and permissions; the caller owns notification configuration outside this storage baseline. |

Logging, encryption, public access, versioning, lifecycle, and KMS policy checks are not skipped. Checkov must include its graph policies: the local Homebrew `3.3.20` package was missing those policy files, so validation also used the complete PyPI distribution with `uv tool run --from checkov==3.3.20 checkov -d . --framework terraform,github_actions --quiet --compact`.
