output "recipe_bucket_name" {
  description = "Name of the recipe storage bucket"
  value       = aws_s3_bucket.recipe_storage.id
}

output "recipe_bucket_arn" {
  description = "ARN of the recipe storage bucket"
  value       = aws_s3_bucket.recipe_storage.arn
}

output "archive_bucket_name" {
  description = "Name of the archive storage bucket"
  value       = aws_s3_bucket.archive_storage.id
}

output "archive_bucket_arn" {
  description = "ARN of the archive storage bucket"
  value       = aws_s3_bucket.archive_storage.arn
}

output "distribution_bucket_name" {
  description = "Name of the distribution bucket"
  value       = aws_s3_bucket.distribution.id
}

output "distribution_bucket_arn" {
  description = "ARN of the distribution bucket"
  value       = aws_s3_bucket.distribution.arn
}
