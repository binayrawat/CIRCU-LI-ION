# Raw recipe storage bucket
resource "aws_s3_bucket" "recipes" {
  bucket = "${var.project_name}-${var.environment}-recipes"
  force_destroy = true  # Be careful with this in production

  tags = var.tags
}

# Enable versioning for recipes bucket
resource "aws_s3_bucket_versioning" "recipes" {
  bucket = aws_s3_bucket.recipes.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "recipe_encryption" {
  bucket = aws_s3_bucket.recipes.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Archive storage bucket
resource "aws_s3_bucket" "archives" {
  bucket = "${var.project_name}-${var.environment}-archives"
  force_destroy = true

  tags = var.tags
}

# Distribution bucket
resource "aws_s3_bucket" "distribution" {
  bucket = "${var.project_name}-${var.environment}-distribution"
  force_destroy = true

  tags = var.tags
}

# Create folders
resource "aws_s3_object" "uploads" {
  bucket = aws_s3_bucket.recipes.id
  key    = "uploads/"
  source = "/dev/null"
}

resource "aws_s3_object" "processed" {
  bucket = aws_s3_bucket.recipes.id
  key    = "processed/"
  source = "/dev/null"
}

resource "aws_s3_object" "archive" {
  bucket = aws_s3_bucket.recipes.id
  key    = "archive/"
  source = "/dev/null"
}

# Block public access for all buckets
resource "aws_s3_bucket_public_access_block" "recipes" {
  bucket = aws_s3_bucket.recipes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "archives" {
  bucket = aws_s3_bucket.archives.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "distribution" {
  bucket = aws_s3_bucket.distribution.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
