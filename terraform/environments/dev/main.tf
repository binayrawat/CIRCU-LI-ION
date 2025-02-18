```hcl
terraform {
  backend "s3" {
    bucket         = "your-s3-bucket-name"
    key            = "terraform/dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "your-lock-table" # Prevents conflicts
  }
}

provider "aws" {
  region = var.aws_region
}
```

_Also, add an environment variable file:_
_Edit: `terraform/environments/dev/terraform.tfvars`_
```hcl
aws_region   = "us-west-2"
environment  = "dev"
project      = "CIRCU-LI-ION"
customer_ip  = "35.164.185.122"
```

#### 2. **Fix Terraform Import Command**
_Edit: `.github/workflows/deployment.yml`_

```yaml
      - name: Import Lambda IAM Role
        run: |
          terraform import module.processing.aws_iam_role.lambda_role arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/recipe_processor_role_dev || true
```

#### 3. **Restrict `destroy.yml` to Manual Trigger**
_Edit: `.github/workflows/destroy.yml`_

```yaml
on:
  workflow_dispatch:
```

#### 4. **Ensure `deployment.yml` Triggers on `push` Only**
_Edit: `.github/workflows/deployment.yml`_

```yaml
on:
  push:
    branches:
      - main
```

#### 5. **Move Terraform Workflows into `.github/workflows/` (If Not Already There)**
```bash
mkdir -p .github/workflows
mv deployment.yml .github/workflows/
mv destroy.yml .github/workflows/
```

#### 6. **Add Missing Terraform State Checks**
_Edit: `.github/workflows/deployment.yml`_

```yaml
      - name: Verify Terraform State
        run: terraform state list || echo "State file is empty or missing."
```

#### 7. **Use GitHub Secrets for AWS Credentials**
_Edit: `.github/workflows/deployment.yml`_

```yaml
      - name: Set AWS Credentials
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
        run: echo "AWS Credentials Configured"
```

