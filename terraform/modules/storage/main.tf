resource "aws_s3_bucket" "recipe_storage" {
  bucket = "recipe-storage-${var.environment}"

  tags = {
    Environment = var.environment
    Project     = "CIRCU-LI-ION"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.recipe_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.recipe_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_user" "customer" {
  name = "recipe-customer-${var.environment}"
}

resource "aws_iam_user_policy" "customer_access" {
  name = "recipe-access"
  user = aws_iam_user.customer.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.recipe_storage.arn}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "recipe_policy" {
  bucket = aws_s3_bucket.recipe_storage.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource  = [
          aws_s3_bucket.recipe_storage.arn,
          "${aws_s3_bucket.recipe_storage.arn}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}
