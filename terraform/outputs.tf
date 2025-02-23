output "batch_compute_environment" {
  value = aws_batch_compute_environment.compute.compute_environment_name
}

output "bucket_name" {
  value = aws_s3_bucket.recipe_storage.id
}

output "cloudfront_domain" {
  value = var.create_cloudfront ? aws_cloudfront_distribution.recipe_cdn[0].domain_name : null
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.customers.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "ecr_repository_url" {
  value = var.create_ecr ? aws_ecr_repository.processor[0].repository_url : null
  description = "The URL of the ECR repository"
}

# ... other outputs ... 