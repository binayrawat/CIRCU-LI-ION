# First, we create a role for our Lambda function
# Think of this like giving our Lambda function an ID badge
resource "aws_iam_role" "lambda_role" {
  name = "recipe_processor_lambda_role_${var.environment}"

  # This part says "Hey, I'm a Lambda function and I need access!"
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
}

# Now we give our Lambda function some permissions
# Like a list of things it's allowed to do
resource "aws_iam_role_policy" "lambda_policy" {
  name = "recipe_processor_lambda_policy_${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # This lets our function read and write recipes in S3
        # Like having keys to the recipe filing cabinet
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        # This lets our function write logs
        # Like keeping a diary of what it's doing
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

# Here's our actual Lambda function
# This is like our robot chef that processes recipes
resource "aws_lambda_function" "recipe_processor" {
  filename         = "${path.module}/../../src/lambda_function.zip"
  function_name    = "recipe_processor_${var.environment}"
  handler          = "index.handler"
  role            = aws_iam_role.lambda_role.arn
  runtime         = "nodejs18.x"
  
  # Increase memory and timeout for large files
  memory_size     = 3008  # Maximum memory
  timeout         = 900   # 15 minutes (maximum)

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      ENV         = var.environment
    }
  }

  # Add tags
  tags = {
    Environment = var.environment
    Project     = var.project
    Name        = "recipe_processor"
  }

  lifecycle {
    ignore_changes = all  # Ignore all changes to prevent recreation
    replace_triggered_by = []  # Don't trigger replacement
  }

  depends_on = [
    aws_iam_role.lambda_role,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Add this before the bucket notification configuration
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recipe_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn

  lifecycle {
    ignore_changes = all
  }
}

# This tells S3 to notify our Lambda when new recipes arrive
# Like a bell that rings when someone drops off a new recipe
resource "aws_s3_bucket_notification" "bucket_notification" {
  # Make sure this depends on the lambda permission
  depends_on = [aws_lambda_permission.allow_s3]
  
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.recipe_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Finally, we give S3 permission to wake up our Lambda
# Like giving the bell permission to wake up our robot chef
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowS3Invoke-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recipe_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn

  lifecycle {
    ignore_changes = all
  }
}

# Add CloudWatch configuration
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project}-recipe-processor"
  retention_in_days = 14
  
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Lambda function error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_sns_topic" "alerts" {
  name = "lambda-alerts-${var.environment}"
}

# Add Batch computing resources for large file processing
resource "aws_batch_compute_environment" "large_file" {
  compute_environment_name = "recipe_processor_batch_${var.environment}"

  compute_resources {
    max_vcpus = 16
    security_group_ids = [aws_security_group.batch.id]
    subnets = data.aws_subnets.default.ids
    type = "FARGATE"
    
    instance_type = ["optimal"]
  }

  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  state        = "ENABLED"
}

resource "aws_batch_job_queue" "large_file" {
  name     = "recipe_processor_queue_${var.environment}"
  state    = "ENABLED"
  priority = 1
  compute_environment_order {
    compute_environment = aws_batch_compute_environment.large_file.arn
    order              = 1
  }
}

# Step Functions for orchestration
resource "aws_sfn_state_machine" "large_file_processor" {
  name     = "recipe_processor_workflow_${var.environment}"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = <<EOF
{
  "StartAt": "CheckFileSize",
  "States": {
    "CheckFileSize": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.fileSize",
          "NumericGreaterThan": 500000000,
          "Next": "InitializeChunking"
        }
      ],
      "Default": "ProcessSmallFile"
    },
    "InitializeChunking": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.chunk_initializer.arn}",
      "Next": "ProcessChunks"
    },
    "ProcessChunks": {
      "Type": "Map",
      "ItemsPath": "$.chunks",
      "Iterator": {
        "StartAt": "ProcessChunk",
        "States": {
          "ProcessChunk": {
            "Type": "Task",
            "Resource": "${aws_batch_job_definition.chunk_processor.arn}",
            "End": true
          }
        }
      },
      "Next": "MergeResults"
    },
    "MergeResults": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.merger.arn}",
      "End": true
    },
    "ProcessSmallFile": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.recipe_processor.arn}",
      "End": true
    }
  }
}
EOF
}

# Lambda function for chunk initialization
resource "aws_lambda_function" "chunk_initializer" {
  filename         = "${path.module}/../../src/chunk_initializer.zip"
  function_name    = "recipe_chunk_initializer_${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 900
  memory_size     = 1024
}

# Batch job definition for chunk processing
resource "aws_batch_job_definition" "chunk_processor" {
  name = "recipe_chunk_processor_${var.environment}"
  type = "container"
  
  container_properties = jsonencode({
    image = "${aws_ecr_repository.processor.repository_url}:latest"
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "4"
      },
      {
        type  = "MEMORY"
        value = "16384"
      }
    ]
  })
}

# VPC and Security Group for Batch
resource "aws_security_group" "batch" {
  name        = "recipe-processor-batch-${var.environment}"
  description = "Security group for Batch compute environment"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data sources for VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ECR Repository
resource "aws_ecr_repository" "processor" {
  name = "recipe-processor-${var.environment}"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM Role for Batch Service
resource "aws_iam_role" "batch_service_role" {
  name = "recipe-processor-batch-service-${var.environment}"

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
}

resource "aws_iam_role_policy_attachment" "batch_service" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "recipe-processor-step-functions-${var.environment}"

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
}

resource "aws_iam_role_policy" "step_functions" {
  name = "recipe-processor-step-functions-${var.environment}"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "batch:SubmitJob",
          "batch:DescribeJobs",
          "batch:TerminateJob",
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
  })
}

# Merger Lambda function
resource "aws_lambda_function" "merger" {
  filename         = "${path.module}/../../src/merger.zip"
  function_name    = "recipe_merger_${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 900
  memory_size     = 3008

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      ENV         = var.environment
    }
  }
}

# Add variables
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for file processing"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

