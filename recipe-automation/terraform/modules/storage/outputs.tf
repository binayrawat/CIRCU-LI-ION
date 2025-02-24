output "recipe_bucket_name" {
  description = "Name of the recipe storage bucket"
  value       = aws_s3_bucket.recipes.id
}

output "recipe_bucket_arn" {
  description = "ARN of the recipe storage bucket"
  value       = aws_s3_bucket.recipes.arn
}

output "recipe_bucket_domain_name" {
  value = aws_s3_bucket.recipes.bucket_regional_domain_name
}

output "archive_bucket_name" {
  description = "Name of the archive storage bucket"
  value       = aws_s3_bucket.archives.id
}

output "archive_bucket_arn" {
  description = "ARN of the archive storage bucket"
  value       = aws_s3_bucket.archives.arn
}

output "distribution_bucket_name" {
  description = "Name of the distribution bucket"
  value       = aws_s3_bucket.distribution.id
}

output "distribution_bucket_arn" {
  description = "ARN of the distribution bucket"
  value       = aws_s3_bucket.distribution.arn
}
