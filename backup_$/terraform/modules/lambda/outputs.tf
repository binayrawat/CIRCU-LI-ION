output "recipe_processor_arn" {
  description = "ARN of the recipe processor Lambda function"
  value       = aws_lambda_function.recipe_processor.arn
}

output "recipe_processor_name" {
  description = "Name of the recipe processor Lambda function"
  value       = aws_lambda_function.recipe_processor.function_name
}

output "archive_creator_arn" {
  description = "ARN of the archive creator Lambda function"
  value       = aws_lambda_function.archive_creator.arn
}

output "archive_creator_name" {
  description = "Name of the archive creator Lambda function"
  value       = aws_lambda_function.archive_creator.function_name
}

output "recipe_processor_log_group_name" {
  description = "Name of the recipe processor CloudWatch log group"
  value       = aws_cloudwatch_log_group.recipe_processor_logs.name
}

output "archive_creator_log_group_name" {
  description = "Name of the archive creator CloudWatch log group"
  value       = aws_cloudwatch_log_group.archive_creator_logs.name
}

output "split_file_lambda_arn" {
  value = aws_lambda_function.split_file.arn
}

output "process_chunk_lambda_arn" {
  value = aws_lambda_function.process_chunk.arn
}

output "merge_results_lambda_arn" {
  value = aws_lambda_function.merge_results.arn
}

output "step_function_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.recipe_processor.arn
}