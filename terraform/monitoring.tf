# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/batch/recipe-processor"
  retention_in_days = 30
  
  tags = local.common_tags
}

# Basic cost monitoring
resource "aws_budgets_budget" "cost" {
  name         = "${local.resource_prefix}-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
  }
}

# Simple dashboard for basic metrics
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.resource_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", aws_s3_bucket.recipe_storage.id],
            ["AWS/Batch", "CPUUtilization", "JobQueue", aws_batch_job_queue.processing_queue.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Basic Resource Metrics"
        }
      }
    ]
  })
}

# Performance monitoring dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.resource_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", aws_s3_bucket.recipe_storage.id],
            ["AWS/Batch", "CPUUtilization", "JobQueue", aws_batch_job_queue.processing_queue.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Resource Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.recipe_cdn.id],
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", aws_cloudfront_distribution.recipe_cdn.id]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"  # CloudFront metrics are in us-east-1
          title  = "Distribution Statistics"
        }
      }
    ]
  })
}

# Batch Job Alerts
resource "aws_cloudwatch_metric_alarm" "job_failures" {
  alarm_name          = "${local.resource_prefix}-job-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "FailedJobCount"
  namespace          = "AWS/Batch"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors job failures"
  alarm_actions      = []  # Add SNS topic ARN if needed

  dimensions = {
    JobQueue = aws_batch_job_queue.processing_queue.name
  }
} 