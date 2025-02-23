# AWS Backup vault
resource "aws_backup_vault" "main" {
  name = "${local.resource_prefix}-vault"
  kms_key_arn = aws_kms_key.main.arn
  
  tags = local.common_tags
}

# AWS Backup plan
resource "aws_backup_plan" "main" {
  name = "${local.resource_prefix}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 12 * * ? *)"  # Daily at 12:00 UTC

    lifecycle {
      delete_after = 30  # Keep backups for 30 days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.main.arn
    }
  }

  tags = local.common_tags
}

# AWS Backup selection
resource "aws_backup_selection" "main" {
  name         = "${local.resource_prefix}-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    aws_s3_bucket.recipe_storage.arn
  ]
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${local.resource_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach AWS Backup service role policy
resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
} 