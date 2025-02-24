# Recipe processor Lambda function
resource "aws_lambda_function" "recipe_processor" {
  filename         = "${path.module}/functions/recipe_processor.zip"
  function_name    = "${var.project_name}-${var.environment}-recipe-processor"
  role            = var.lambda_role_arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 900
  memory_size     = 3008

  ephemeral_storage {
    size = 10240
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      RECIPE_BUCKET  = var.recipe_bucket_name
      ARCHIVE_BUCKET = var.archive_bucket_name
      ENVIRONMENT    = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-recipe-processor"
    }
  )
}

# Archive creator Lambda function
resource "aws_lambda_function" "archive_creator" {
  filename         = "${path.module}/functions/archive_creator.zip"
  function_name    = "${var.project_name}-${var.environment}-archive-creator"
  role            = var.lambda_role_arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 512

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      RECIPE_BUCKET  = var.recipe_bucket_name
      ARCHIVE_BUCKET = var.archive_bucket_name
      ENVIRONMENT    = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-archive-creator"
    }
  )
}

# S3 trigger for recipe processor
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recipe_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.recipe_bucket_name}"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "recipe_processor_logs" {
  name              = "/aws/lambda/${aws_lambda_function.recipe_processor.function_name}"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "archive_creator_logs" {
  name              = "/aws/lambda/${aws_lambda_function.archive_creator.function_name}"
  retention_in_days = 14

  tags = var.tags
}

# Split file Lambda function
resource "aws_lambda_function" "split_file" {
  filename         = "${path.module}/functions/split_file.zip"
  function_name    = "${var.project_name}-${var.environment}-split-file"
  role            = var.lambda_role_arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      ENVIRONMENT       = var.environment
      STEP_FUNCTION_ARN = aws_sfn_state_machine.recipe_processor.arn
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  tags = var.tags
}

# Process chunk Lambda function
resource "aws_lambda_function" "process_chunk" {
  filename         = "${path.module}/functions/process_chunk.zip"
  function_name    = "${var.project_name}-${var.environment}-process-chunk"
  role            = var.lambda_role_arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 1024

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = var.tags
}

# Merge results Lambda function
resource "aws_lambda_function" "merge_results" {
  filename         = "${path.module}/functions/merge_results.zip"
  function_name    = "${var.project_name}-${var.environment}-merge-results"
  role            = var.lambda_role_arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 1024

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = var.tags
}

# Then create the Step Functions state machine
resource "aws_sfn_state_machine" "recipe_processor" {
  name     = "${var.project_name}-${var.environment}-recipe-processor"
  role_arn = var.step_functions_role_arn

  definition = jsonencode({
    Comment = "Recipe processing workflow"
    StartAt = "ProcessChunks"
    States = {
      ProcessChunks = {
        Type = "Map"
        ItemsPath = "$.chunks"
        MaxConcurrency = 5
        Iterator = {
          StartAt = "ProcessChunk"
          States = {
            ProcessChunk = {
              Type = "Task"
              Resource = aws_lambda_function.process_chunk.arn
              Retry = [
                {
                  ErrorEquals = ["Lambda.TooManyRequestsException"],
                  IntervalSeconds = 1,
                  BackoffRate = 2,
                  MaxAttempts = 5
                }
              ]
              End = true
            }
          }
        }
        Next = "MergeResults"
      }
      MergeResults = {
        Type = "Task"
        Resource = aws_lambda_function.merge_results.arn
        End = true
      }
    }
  })

  tags = var.tags
}

# Remove both notification blocks first
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Then add the new notification with proper permissions
resource "aws_lambda_permission" "allow_s3_split_file" {
  statement_id  = "AllowS3InvokeSplitFile"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.split_file.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.recipe_bucket_name}"
}

# Add S3 to Step Functions trigger
resource "aws_lambda_permission" "allow_s3_step_functions" {
  statement_id  = "AllowS3InvokeStepFunctions"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.split_file.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.recipe_bucket_name}"
}

resource "aws_s3_bucket_notification" "recipe_upload" {
  bucket = var.recipe_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.split_file.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".json"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_split_file,
    aws_lambda_permission.allow_s3_step_functions
  ]
}

# Add CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "split_file_logs" {
  name              = "/aws/lambda/${aws_lambda_function.split_file.function_name}"
  retention_in_days = 14
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "process_chunk_logs" {
  name              = "/aws/lambda/${aws_lambda_function.process_chunk.function_name}"
  retention_in_days = 14
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "merge_results_logs" {
  name              = "/aws/lambda/${aws_lambda_function.merge_results.function_name}"
  retention_in_days = 14
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/vendedlogs/states/${aws_sfn_state_machine.recipe_processor.name}"
  retention_in_days = 14
  tags = var.tags
}
