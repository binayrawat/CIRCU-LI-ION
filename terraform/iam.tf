# Batch service role
resource "aws_iam_role" "batch_service_role" {
  name = "${local.resource_prefix}-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Batch execution role
resource "aws_iam_role" "batch_execution_role" {
  name = "${local.resource_prefix}-batch-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# S3 access policy
resource "aws_iam_role_policy" "batch_s3_policy" {
  name = "${local.resource_prefix}-s3-access"
  role = aws_iam_role.batch_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.recipe_storage.arn,
          "${aws_s3_bucket.recipe_storage.arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch logs policy
resource "aws_iam_role_policy" "batch_cloudwatch_policy" {
  name = "${local.resource_prefix}-cloudwatch-access"
  role = aws_iam_role.batch_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
} 