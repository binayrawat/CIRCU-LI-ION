# Provider configuration
provider "aws" {
  region = "us-west-2"
}

# Random string for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket for recipe storage
resource "aws_s3_bucket" "recipe_storage" {
  bucket = "${var.bucket_name_prefix}-${var.environment}"
  
  tags = {
    Environment = var.environment
    Project     = "CIRCU-LI-ION"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.recipe_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.recipe_storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.recipe_storage.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

# Cognito User Pool for customer access
resource "aws_cognito_user_pool" "customers" {
  name = "recipe-customers-${var.environment}"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  
  username_attributes = ["email"]
  
  tags = {
    Environment = var.environment
    Project     = "CIRCU-LI-ION"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "recipe-client"
  user_pool_id = aws_cognito_user_pool.customers.id
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# Comment out or remove VPN-related resources
# resource "aws_vpn_gateway" "vpn_gateway" {
#   vpc_id = var.vpc_id
#   
#   tags = {
#     Name = "recipe-vpn-gateway-${var.environment}"
#   }
# }

# resource "aws_customer_gateway" "main" {
#   bgp_asn    = 65000
#   ip_address = var.customer_ip
#   type       = "ipsec.1"
#   
#   tags = {
#     Name = "recipe-customer-gateway-${var.environment}"
#   }
# }

# resource "aws_vpn_connection" "main" {
#   vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
#   customer_gateway_id = aws_customer_gateway.main.id
#   type               = "ipsec.1"
#   static_routes_only = true
# }

# CloudFront distribution for global delivery
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for recipe distribution"
}

resource "aws_cloudfront_distribution" "recipe_cdn" {
  count = var.create_cloudfront ? 1 : 0
  
  enabled             = true
  is_ipv6_enabled    = true
  default_root_object = "index.html"
  
  origin {
    domain_name = aws_s3_bucket.recipe_storage.bucket_regional_domain_name
    origin_id   = "S3Origin"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"
    
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
  
  tags = {
    Environment = var.environment
  }
}

# Update S3 bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "cloudfront_access" {
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

# ECR Repository
resource "aws_ecr_repository" "processor" {
  count = var.create_ecr ? 1 : 0
  
  name = "recipe-processor-dev-${random_string.suffix.result}"
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Environment = "dev"
    Project     = "CIRCU-LI-ION"
  }
}

# Batch compute environment
resource "aws_batch_compute_environment" "compute" {
  compute_environment_name = "recipe-compute-${var.environment}"

  compute_resources {
    max_vcpus = var.batch_max_vcpus
    type      = "FARGATE"
    
    security_group_ids = [var.security_group_id]
    subnets           = [var.subnet_id]
  }

  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  state        = "ENABLED"
}

# IAM Roles
resource "aws_iam_role" "batch_service_role" {
  name = "recipe-batch-service-${var.environment}"

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

# Add CloudWatch Logs policy to Batch service role
resource "aws_iam_role_policy_attachment" "batch_cloudwatch" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role_policy" "batch_cloudwatch_logs" {
  name = "batch-cloudwatch-logs"
  role = aws_iam_role.batch_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for Task Execution
resource "aws_iam_role" "task_role" {
  name = "recipe-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# S3 access policy for task role
resource "aws_iam_role_policy" "task_s3_policy" {
  name = "s3-access-${var.environment}"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.recipe_storage.arn,
          "${aws_s3_bucket.recipe_storage.arn}/*"
        ]
      }
    ]
  })
}

# Batch job queue
resource "aws_batch_job_queue" "processing_queue" {
  name = "recipe-processing-queue-${var.environment}"
  state = "ENABLED"
  priority = 1

  compute_environment_order {
    order = 0
    compute_environment = aws_batch_compute_environment.compute.arn
  }
}

# Batch Job Definition
resource "aws_batch_job_definition" "processor" {
  name = "recipe-processor-${var.environment}"
  type = "container"
  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({
    image = "${aws_ecr_repository.processor.repository_url}:latest"
    
    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }
    
    resourceRequirements = [
      {
        type  = "VCPU"
        value = tostring(var.batch_vcpus)
      },
      {
        type  = "MEMORY"
        value = tostring(var.batch_memory)
      }
    ]
    
    environment = [
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "BUCKET_NAME"
        value = aws_s3_bucket.recipe_storage.id
      }
    ]
    
    executionRoleArn = aws_iam_role.task_role.arn
    jobRoleArn       = aws_iam_role.task_role.arn
  })
} 