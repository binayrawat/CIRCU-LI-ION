variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "s3_bucket_domain_name" {
  type        = string
  description = "S3 bucket regional domain name"
}

variable "s3_bucket_arn" {
  type        = string
  description = "S3 bucket ARN"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
} 