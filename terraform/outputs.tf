output "cloudfront_domain" {
  value = var.create_cloudfront ? aws_cloudfront_distribution.recipe_cdn[0].domain_name : null
}

output "ecr_repository_url" {
  value = var.create_ecr ? aws_ecr_repository.processor[0].repository_url : null
}

# ... other outputs ... 