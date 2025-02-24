output "distribution_id" {
  value       = aws_cloudfront_distribution.recipe_distribution.id
  description = "CloudFront distribution ID"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.recipe_distribution.domain_name
  description = "CloudFront distribution domain name"
}

output "oai_iam_arn" {
  value       = aws_cloudfront_origin_access_identity.oai.iam_arn
  description = "CloudFront OAI IAM ARN"
} 