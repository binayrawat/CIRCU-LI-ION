variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
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