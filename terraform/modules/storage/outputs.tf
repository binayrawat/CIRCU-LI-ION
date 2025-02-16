# This gives us the name of our S3 bucket
# Like the name tag on our digital filing cabinet, so we can find it later
output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.recipe_storage.id
}

# This is the bucket's unique ID (ARN)
# Think of it as the serial number AWS uses to identify our filing cabinet
output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.recipe_storage.arn
}

output "bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.recipe_storage.bucket_domain_name
}

