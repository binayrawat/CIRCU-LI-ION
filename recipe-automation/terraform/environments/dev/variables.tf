variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "recipe-automation"
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Project     = "recipe-automation"
    Environment = "dev"
    Terraform   = "true"
  }
}
