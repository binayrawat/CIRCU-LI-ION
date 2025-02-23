# KMS key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for recipe encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

# S3 bucket encryption (using AWS managed key to save costs)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.recipe_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# VPC Security Group for Batch
resource "aws_security_group" "batch_sg" {
  name        = "${local.resource_prefix}-batch-sg"
  description = "Security group for Batch compute environment"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.recipe_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
} 