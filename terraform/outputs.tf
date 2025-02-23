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

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.processor.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for recipe storage"
  value       = aws_s3_bucket.recipe_storage.id
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.recipe_cdn.domain_name
}

output "batch_job_queue" {
  description = "AWS Batch job queue ARN"
  value       = aws_batch_job_queue.processing_queue.arn
}

output "vpn_connection_id" {
  description = "VPN Connection ID"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].id : null
}

output "monitoring_dashboard" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

# ... other outputs ... 