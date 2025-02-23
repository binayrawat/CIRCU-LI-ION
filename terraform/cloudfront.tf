# CloudFront distribution
resource "aws_cloudfront_distribution" "recipe_cdn" {
  enabled             = true
  is_ipv6_enabled    = true
  price_class        = "PriceClass_100"
  http_version       = "http2"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.recipe_storage.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.recipe_storage.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.recipe_storage.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${local.resource_prefix}"
}

# S3 bucket policy for CloudFront
resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.recipe_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.recipe_storage.arn}/*"
      }
    ]
  })
} 