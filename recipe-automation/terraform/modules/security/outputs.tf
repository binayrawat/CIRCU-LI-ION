output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.recipe_key.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.recipe_key.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.name
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda_sg.id
}
