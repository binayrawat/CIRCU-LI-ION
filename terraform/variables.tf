variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "recipe-manager"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 900
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.9"
}

variable "storage_config" {
  description = "Storage configuration"
  type = object({
    bucket_prefix = string
    versioning_enabled = bool
    encryption_enabled = bool
  })
  default = {
    bucket_prefix = "recipe-storage"
    versioning_enabled = true
    encryption_enabled = true
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "recipe-manager"
    Environment = "dev"
  }
}

# VPN Configuration
variable "customer_gateway_asn" {
  description = "ASN for customer gateway"
  type        = number
  default     = 65000
}

variable "customer_gateway_ip" {
  description = "Customer gateway public IP"
  type        = string
}

# Cost Management
variable "monthly_budget" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100  # Free tier consideration
}

variable "alert_emails" {
  description = "Email addresses for cost alerts"
  type        = list(string)
  default     = []
}

# Edge Computing
variable "edge_device_count" {
  description = "Number of edge devices"
  type        = number
  default     = 1
}

variable "enable_vpn" {
  description = "Enable VPN connection (additional costs)"
  type        = bool
  default     = false  # Disable by default
}

variable "batch_max_vcpus" {
  description = "Maximum vCPUs for Batch environment"
  type        = number
  default     = 2  # Reduced from 16 to minimize costs
}

variable "enable_spot" {
  description = "Use spot instances for cost savings"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable AWS Backup"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
