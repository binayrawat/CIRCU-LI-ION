resource "aws_lambda_function" "recipe_processor" {
  filename         = var.lambda_zip_path
  function_name    = "recipe_processor_${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_${var.environment}"
  # Define the assume role policy and attach necessary policies
}

