variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda function ZIP file"
  type        = string
  default     = "../../src/lambda_function/lambda_function.zip"
}

variable "customer_ip" {
  type        = string
  description = "Customer IP address for security group rules"
}

variable "customer_cidr" {
  description = "Customer network CIDR"
  type        = string
  default     = "192.168.0.0/16"
} 