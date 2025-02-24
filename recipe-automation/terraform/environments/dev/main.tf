module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

module "storage" {
  source = "../../modules/storage"

  project_name     = var.project_name
  environment      = var.environment
  cloudfront_oai_id = module.cloudfront.origin_access_identity_id
  tags            = var.tags
}

module "security" {
  source = "../../modules/security"

  project_name            = var.project_name
  environment            = var.environment
  vpc_id                 = module.network.vpc_id
  recipe_bucket_arn      = module.storage.recipe_bucket_arn
  archive_bucket_arn     = module.storage.archive_bucket_arn
  distribution_bucket_arn = module.storage.distribution_bucket_arn
  split_file_lambda_arn  = module.lambda.split_file_lambda_arn
  process_chunk_lambda_arn = module.lambda.process_chunk_lambda_arn
  merge_results_lambda_arn = module.lambda.merge_results_lambda_arn
  tags                   = var.tags
}

module "lambda" {
  source = "../../modules/lambda"

  project_name             = var.project_name
  environment             = var.environment
  lambda_role_arn         = module.security.lambda_role_arn
  lambda_security_group_id = module.security.lambda_security_group_id
  private_subnet_ids      = module.network.private_subnet_ids
  recipe_bucket_name      = module.storage.recipe_bucket_name
  archive_bucket_name     = module.storage.archive_bucket_name
  step_functions_role_arn = module.security.step_functions_role_arn
  tags                    = var.tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name         = var.project_name
  environment         = var.environment
  s3_bucket_domain_name = module.storage.recipe_bucket_domain_name
  s3_bucket_arn        = module.storage.recipe_bucket_arn
  tags                = var.tags
}
