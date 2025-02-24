# KMS key for recipe encryption
resource "aws_kms_key" "recipe_key" {
  description             = "KMS key for recipe encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-recipe-key"
    }
  )
}

resource "aws_kms_alias" "recipe_key_alias" {
  name          = "alias/${var.project_name}-${var.environment}-recipe-key"
  target_key_id = aws_kms_key.recipe_key.key_id
}

# Security Group for Lambda functions
resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-${var.environment}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lambda-sg"
    }
  )
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Lambda to access S3 buckets
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.project_name}-${var.environment}-lambda-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          var.recipe_bucket_arn,
          "${var.recipe_bucket_arn}/*",
          var.archive_bucket_arn,
          "${var.archive_bucket_arn}/*",
          var.distribution_bucket_arn,
          "${var.distribution_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda CloudWatch logs policy
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "${var.project_name}-${var.environment}-lambda-logs-policy"
  role = aws_iam_role.lambda_role.id

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
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

# Step Functions IAM Role
resource "aws_iam_role" "step_functions" {
  name = "${var.project_name}-${var.environment}-step-functions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Step Functions IAM Policy
resource "aws_iam_role_policy" "step_functions" {
  name = "${var.project_name}-${var.environment}-step-functions"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          "${var.split_file_lambda_arn}",
          "${var.process_chunk_lambda_arn}",
          "${var.merge_results_lambda_arn}"
        ]
      }
    ]
  })
}

# Add Step Functions invoke permission to Lambda role
resource "aws_iam_role_policy" "lambda_step_functions" {
  name = "${var.project_name}-${var.environment}-lambda-step-functions"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = [
          "arn:aws:states:us-west-2:202533497212:stateMachine:recipe-automation-${var.environment}-recipe-processor"
        ]
      }
    ]
  })
}

# Add CloudWatch Logs permissions to Lambda role
resource "aws_iam_role_policy" "lambda_cloudwatch" {
  name = "${var.project_name}-${var.environment}-lambda-cloudwatch"
  role = aws_iam_role.lambda_role.id

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
        Resource = [
          "arn:aws:logs:us-west-2:202533497212:log-group:/aws/lambda/recipe-automation-${var.environment}-*:*"
        ]
      }
    ]
  })
}

# Output the role ARN
output "step_functions_role_arn" {
  value = aws_iam_role.step_functions.arn
}
