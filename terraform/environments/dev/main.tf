provider "aws" {
  region = var.aws_region
}

# Storage Module
module "storage" {
  source      = "../../modules/storage"
  environment = var.environment
  project     = var.project
  customer_ip = var.customer_ip
}

# Processing Module
module "processing" {
  source              = "../../modules/processing"
  lambda_function_arn = aws_lambda_function.recipe_processor.arn
  environment         = var.environment
  project            = var.project
  bucket_name        = module.storage.bucket_name
  bucket_arn         = module.storage.bucket_arn
  lambda_zip_path    = var.lambda_zip_path
}

# Distribution Module
module "distribution" {
  source             = "../../modules/distribution"
  environment        = var.environment
  project            = var.project
  bucket_name        = module.storage.bucket_name
  bucket_arn         = module.storage.bucket_arn
  bucket_domain_name = module.storage.bucket_domain_name
}

# VPN Module (Commented for initial deployment)
/*
module "network" {
  source        = "../../modules/network"
  environment   = var.environment
  project       = var.project
  customer_ip   = var.customer_ip
  customer_cidr = var.customer_cidr
}
*/

