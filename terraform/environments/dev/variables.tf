variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "CIRCU-LI-ION"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda function ZIP file"
  type        = string
  default     = "../../src/lambda_function/lambda_function.zip"
}

variable "customer_ip" {
  description = "Customer gateway public IP"
  type        = string
}

variable "customer_cidr" {
  description = "Customer network CIDR"
  type        = string
  default     = "192.168.0.0/16"
} 