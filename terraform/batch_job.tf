# Batch Job Definition
resource "aws_batch_job_definition" "processor" {
  name = "${local.resource_prefix}-job"
  type = "container"
  platform_capabilities = ["EC2"]
  propagate_tags = true

  container_properties = jsonencode({
    image = "public.ecr.aws/docker/library/python:3.9-slim"  # Using public Python image
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "4"
      },
      {
        type  = "MEMORY"
        value = "16384"  # 16GB for large file processing
      }
    ]
    command = ["python", "-c", file("${path.module}/../src/processor/process.py")]
    executionRoleArn = aws_iam_role.batch_execution_role.arn
    jobRoleArn       = aws_iam_role.batch_execution_role.arn
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/batch/recipe-processor"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "recipe"
      }
    }
    environment = [
      {
        name  = "OUTPUT_BUCKET"
        value = aws_s3_bucket.recipe_storage.id
      },
      {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    ]
  })

  tags = local.common_tags
} 