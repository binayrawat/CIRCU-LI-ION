# Hey! This is where we set up our storage bucket - think of it like a big digital filing cabinet
# We're using S3 which is Amazon's storage service
resource "aws_s3_bucket" "recipe_storage" {
  # We name our bucket based on whether it's for testing or real use
  bucket = "recipe-storage-${var.environment}"

  # These tags help us keep track of which bucket is which
  tags = {
    Environment = var.environment
    Project     = "CIRCU-LI-ION"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# We want to keep old versions of our files, just in case we need them later
# Like keeping old drafts of a recipe
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.recipe_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# We also want to make sure our recipes are stored securely
# This encrypts everything - like putting files in a safe
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.recipe_storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Now we create a special user account for our customer
# It's like giving them their own key to access their recipes
resource "aws_iam_user" "customer" {
  name = "recipe-customer-${var.environment}"
}

# Here we set up what the customer is allowed to do
# They can only read recipes, not change or delete them
resource "aws_iam_user_policy" "customer_access" {
  name = "recipe-access"
  user = aws_iam_user.customer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = ["${aws_s3_bucket.recipe_storage.arn}/*"]
      }
    ]
  })
}

# Add bucket policy
resource "aws_s3_bucket_policy" "recipe_policy" {
  bucket = aws_s3_bucket.recipe_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.recipe_storage.arn,
          "${aws_s3_bucket.recipe_storage.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}
