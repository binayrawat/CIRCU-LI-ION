output "step_function_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.lambda.step_function_arn
} 