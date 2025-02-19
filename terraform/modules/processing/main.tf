# First, we create a role for our Lambda function
# Think of this like giving our Lambda function an ID badge
resource "aws_iam_role" "lambda_role" {
  name = "recipe_processor_role_${var.environment}"

  # This part says "Hey, I'm a Lambda function and I need access!"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Now we give our Lambda function some permissions
# Like a list of things it's allowed to do
resource "aws_iam_role_policy" "lambda_policy" {
  name = "recipe_processor_policy"
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
          "s3:ListBucket"
        ]
        Resource = [
          var.bucket_arn,
          "${var.bucket_arn}/*"
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
  filename      = var.lambda_zip_path
  function_name = "recipe_processor_${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  # These are like settings we tell our robot chef about
  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      ENV         = var.environment
    }
  }

  # Labels to keep track of which robot chef is which
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# This tells S3 to notify our Lambda when new recipes arrive
# Like a bell that rings when someone drops off a new recipe
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.recipe_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Ensure the Lambda function can be invoked by S3
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recipe_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

# Finally, we give S3 permission to wake up our Lambda
# Like giving the bell permission to wake up our robot chef
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recipe_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
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

