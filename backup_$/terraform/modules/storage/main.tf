# Raw recipe storage bucket
resource "aws_s3_bucket" "recipe_storage" {
  bucket = "${var.project_name}-${var.environment}-recipes"
  force_destroy = true  # Be careful with this in production

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-recipes"
    }
  )
}

# Enable versioning
resource "aws_s3_bucket_versioning" "recipe_storage" {
  bucket = aws_s3_bucket.recipe_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "recipe_encryption" {
  bucket = aws_s3_bucket.recipe_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Archive storage bucket
resource "aws_s3_bucket" "archive_storage" {
  bucket = "${var.project_name}-${var.environment}-archives"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-archives"
    }
  )
}

# Distribution bucket
resource "aws_s3_bucket" "distribution" {
  bucket = "${var.project_name}-${var.environment}-distribution"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-distribution"
    }
  )
}

# Create folders
resource "aws_s3_object" "uploads" {
  bucket = aws_s3_bucket.recipe_storage.id
  key    = "uploads/"
  source = "/dev/null"
}

resource "aws_s3_object" "processed" {
  bucket = aws_s3_bucket.recipe_storage.id
  key    = "processed/"
  source = "/dev/null"
}

resource "aws_s3_object" "archive" {
  bucket = aws_s3_bucket.recipe_storage.id
  key    = "archive/"
  source = "/dev/null"
}
