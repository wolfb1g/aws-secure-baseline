locals {
  cis_standards_arn = (
    var.securityhub_cis_version == "1.2.0"
    ? "arn:${data.aws_partition.current.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
    : "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.current.region}::standards/cis-aws-foundations-benchmark/v/${var.securityhub_cis_version}"
  )
}

resource "aws_securityhub_account" "this" {
  enable_default_standards  = false
  auto_enable_controls      = true
  control_finding_generator = "SECURITY_CONTROL"

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = local.cis_standards_arn

  depends_on = [aws_securityhub_account.this]
}
