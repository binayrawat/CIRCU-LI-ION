# CIRCU-LI-ION Robot Recipe Manager

## Overview
Cloud infrastructure for managing robot automation recipes, enabling secure storage, processing, and distribution of recipe files.

## Architecture Components
- S3 for secure storage with versioning
- AWS Batch for large file processing
- CloudFront for global distribution
- IAM for access control

## Prerequisites
- AWS Account
- AWS CLI configured
- Terraform installed
- Docker installed
- Python 3.8+

## Deployment Steps

### 1. Local Deployment
```bash
# Install Python requirements
pip install -r src/processor/requirements.txt
pip install -r src/scripts/requirements.txt

# Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# Build and push Docker image
cd ../src/processor
docker build -t recipe-processor .
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 202533497212.dkr.ecr.us-west-2.amazonaws.com
docker tag recipe-processor:latest 202533497212.dkr.ecr.us-west-2.amazonaws.com/recipe-processor:latest
docker push 202533497212.dkr.ecr.us-west-2.amazonaws.com/recipe-processor:latest
```

### 2. Usage
```bash
# Upload a recipe
cd ../scripts
python upload_recipe.py --file recipe.json --bucket circu-li-ion-dev-us-west-2
```

## Security Features
- S3 encryption at rest
- HTTPS for transmission
- IAM role-based access
- Secure VPC configuration

## Cost Optimization
- S3 Intelligent-Tiering
- CloudFront caching
- Batch for cost-effective processing

## Troubleshooting
Common issues and solutions:
1. Docker build fails: Check Docker installation and permissions
2. Terraform errors: Verify AWS credentials and region
3. Upload fails: Check S3 bucket permissions
