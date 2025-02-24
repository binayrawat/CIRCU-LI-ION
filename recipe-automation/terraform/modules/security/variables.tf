variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "recipe_bucket_arn" {
  description = "ARN of the recipe bucket"
  type        = string
}

variable "archive_bucket_arn" {
  description = "ARN of the archive bucket"
  type        = string
}

variable "distribution_bucket_arn" {
  description = "ARN of the distribution bucket"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "split_file_lambda_arn" {
  description = "ARN of the split file Lambda function"
  type        = string
}

variable "process_chunk_lambda_arn" {
  description = "ARN of the process chunk Lambda function"
  type        = string
}

variable "merge_results_lambda_arn" {
  description = "ARN of the merge results Lambda function"
  type        = string
}
