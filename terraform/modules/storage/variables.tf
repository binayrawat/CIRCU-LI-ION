# This tells us if we're working in dev, staging, or production
# Like different kitchens for different purposes
variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

# Just our project name to keep track of things
# In this case it's for our robot recipe system
variable "project" {
  description = "Project name"
  type        = string
  default     = "CIRCU-LI-ION"
}

variable "customer_ip" {
  description = "Customer's IP address"
  type        = string
}

