variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "CIRCU-LI-ION"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "lambda_zip_path" {
  default = "../../src/lambda_function/lambda_function.zip"
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function for processing S3 events"
  type        = string
}

