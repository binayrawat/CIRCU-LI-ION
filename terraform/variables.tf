variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Batch compute environment"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Batch compute environment"
  type        = string
}

variable "customer_ip" {
  description = "Customer gateway IP address for VPN connection"
  type        = string
}

# Optional: Configure these if you want to customize the solution
variable "batch_max_vcpus" {
  description = "Maximum vCPUs for Batch compute environment"
  type        = number
  default     = 16
}

variable "batch_memory" {
  description = "Memory (in MiB) for Batch jobs"
  type        = number
  default     = 16384  # 16GB
}

variable "batch_vcpus" {
  description = "vCPUs for Batch jobs"
  type        = number
  default     = 4
}

variable "bucket_name_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "recipe-storage"
}

variable "cognito_user_pool_name" {
  description = "Name for the Cognito user pool"
  type        = string
  default     = "recipe-customers"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "existing_cloudfront_id" {
  description = "ID of existing CloudFront distribution"
  type        = string
  default     = ""
}

variable "existing_ecr_image" {
  description = "Existing ECR image URL"
  type        = string
  default     = "public.ecr.aws/amazonlinux/amazonlinux:latest"  # Default fallback image
}

variable "create_cloudfront" {
  description = "Whether to create CloudFront distribution"
  type        = bool
  default     = true
}

variable "create_ecr" {
  description = "Whether to create ECR repository"
  type        = bool
  default     = true
} 