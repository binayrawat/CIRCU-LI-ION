# Recipe bucket
resource "aws_s3_bucket" "recipes" {
  bucket = "${var.project_name}-${var.environment}-recipes"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      server_side_encryption_configuration,
      versioning,
      grant
    ]
  }

  tags = var.tags
}

# Archive bucket
resource "aws_s3_bucket" "archives" {
  bucket = "${var.project_name}-${var.environment}-archives"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      server_side_encryption_configuration,
      versioning,
      grant
    ]
  }

  tags = var.tags
}

# Distribution bucket
resource "aws_s3_bucket" "distribution" {
  bucket = "${var.project_name}-${var.environment}-distribution"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      server_side_encryption_configuration,
      versioning,
      grant
    ]
  }

  tags = var.tags
}

# Enable versioning for recipes bucket
resource "aws_s3_bucket_versioning" "recipes" {
  bucket = aws_s3_bucket.recipes.id
  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    ignore_changes = all
  }
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

# Create folder structure in recipes bucket
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
