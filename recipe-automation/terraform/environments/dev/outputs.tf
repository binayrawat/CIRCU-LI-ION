output "step_function_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.lambda.step_function_arn
}

output "cloudfront_distribution_domain" {
  value = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
} 