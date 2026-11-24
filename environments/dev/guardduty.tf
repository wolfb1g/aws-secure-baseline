resource "aws_guardduty_detector" "this" {
  #checkov:skip=CKV2_AWS_3:AWS Organizations GuardDuty configuration (aws_guardduty_organization_configuration) is out of scope because this baseline targets a single standalone AWS account per docs/PROJECT_BRIEF.md Sections 1 and 3.
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_guardduty_detector_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.this.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "eks_audit_logs" {
  detector_id = aws_guardduty_detector.this.id
  name        = "EKS_AUDIT_LOGS"
  status      = var.guardduty_enable_eks_audit_logs ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  detector_id = aws_guardduty_detector.this.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = var.guardduty_enable_ebs_malware_protection ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "rds_login_events" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RDS_LOGIN_EVENTS"
  status      = var.guardduty_enable_rds_login_events ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "lambda_network_logs" {
  detector_id = aws_guardduty_detector.this.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = var.guardduty_enable_lambda_network_logs ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  status      = var.guardduty_enable_runtime_monitoring ? "ENABLED" : "DISABLED"
}
