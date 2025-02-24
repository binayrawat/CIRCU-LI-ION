output "distribution_id" {
  description = "The identifier for the CloudFront distribution"
  value       = aws_cloudfront_distribution.recipe_distribution.id
}

output "distribution_domain_name" {
  description = "The domain name corresponding to the CloudFront distribution"
  value       = aws_cloudfront_distribution.recipe_distribution.domain_name
}

output "distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the CloudFront distribution"
  value       = aws_cloudfront_distribution.recipe_distribution.arn
}

output "oai_iam_arn" {
  value       = aws_cloudfront_origin_access_identity.oai.iam_arn
  description = "CloudFront OAI IAM ARN"
}

output "origin_access_identity_id" {
  description = "The ID of the CloudFront Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.oai.id
} 