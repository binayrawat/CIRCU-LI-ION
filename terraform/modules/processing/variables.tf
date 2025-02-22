variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "CIRCU-LI-ION"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for file processing"
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda function ZIP file"
  type        = string
  default     = "../../src/lambda_function/lambda_function.zip"
}

