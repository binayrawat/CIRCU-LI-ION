variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

variable "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for Lambda functions"
  type        = list(string)
}

variable "recipe_bucket_name" {
  description = "Name of the recipe S3 bucket"
  type        = string
}

variable "archive_bucket_name" {
  description = "Name of the archive S3 bucket"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "step_functions_role_arn" {
  description = "ARN of the IAM role for Step Functions state machine"
  type        = string
}
