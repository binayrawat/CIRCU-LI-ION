# Recipe Manager Infrastructure

## Overview
Secure and cost-effective infrastructure for managing robot automation recipes.

## Core Components
- S3 for secure storage
- AWS Batch for large file processing
- Basic monitoring and alerting

## Features
- ✅ Secure file storage with versioning
- ✅ Large file processing (1GB+)
- ✅ Cost monitoring and alerts
- ✅ Basic security controls

## Prerequisites
- AWS Account
- Terraform >= 1.0.0
- Python 3.9+

## Quick Start
```bash
# Initialize Terraform
cd terraform
terraform init

# Deploy infrastructure
terraform apply
```

## Cost Optimization
- Uses S3 standard storage
- Spot instances for processing
- Basic monitoring included
- Free tier compatible where possible

## Security
- S3 encryption enabled
- Public access blocked
- Security groups configured
- IAM roles with minimal permissions

## Monitoring
- Basic CloudWatch metrics
- Cost alerts
- Processing job monitoring

## Directory Structure
```
.
├── src/
│   └── processor/
│       ├── process.py        # Processing logic
│       └── requirements.txt  # Dependencies
├── terraform/
│   ├── main.tf              # Core infrastructure
│   ├── variables.tf         # Variables
│   ├── providers.tf         # AWS provider
│   ├── outputs.tf           # Outputs
│   ├── security.tf          # Security config
│   └── monitoring.tf        # Basic monitoring
└── README.md
```

## Troubleshooting
1. Job Failures
   - Check CloudWatch logs
   - Verify IAM permissions
   - Check resource limits

2. Performance Issues
   - Monitor CPU/Memory metrics
   - Check network connectivity
   - Verify file sizes

3. Cost Management
   - Review budget alerts
   - Check resource utilization
   - Optimize storage tiers
