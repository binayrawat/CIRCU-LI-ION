# Cost Optimization Guide

## Free Tier Usage
1. S3:
   - First 5GB storage free
   - 20,000 GET requests
   - 2,000 PUT requests

2. AWS Batch:
   - Uses EC2 Spot instances for cost reduction
   - Auto-scaling based on workload

3. CloudFront:
   - First 50GB transfer free
   - 2,000,000 HTTP/HTTPS requests

## Optimization Strategies
1. Storage:
   - S3 Lifecycle policies
   - Intelligent-Tiering
   - Regular cleanup of old versions

2. Processing:
   - Spot instances for Batch jobs
   - Right-sized compute resources
   - Efficient job scheduling

3. Network:
   - CloudFront caching
   - Regional optimization
   - Compression 