terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  required_version = ">= 1.0.0"
  
  # If you want to use remote state, uncomment and configure this:
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "circu-li-ion/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

provider "random" {} 