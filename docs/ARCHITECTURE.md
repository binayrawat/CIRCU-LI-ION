# CIRCU-LI-ION Architecture

## System Overview
The CIRCU-LI-ION system provides a secure, scalable infrastructure for managing robot automation recipes.

## Components

### 1. Storage Layer (AWS S3)
- Secure storage for recipes with versioning
- Handles large files (1+ GB) and small configuration files
- Encryption at rest using AES-256
- Lifecycle policies for cost optimization

### 2. Authentication Layer (Amazon Cognito)
- Customer authentication and authorization
- Secure access control to recipes
- Integration with CloudFront for distribution

### 3. Processing Layer (AWS Batch)
- Containerized processing for recipe consolidation
- Scalable compute resources
- Cost-effective processing using Fargate

### 4. Distribution Layer (CloudFront)
- Global content delivery network
- Edge caching for improved performance
- HTTPS encryption for secure transmission
- Integration with Cognito for authentication

### 5. Network Layer (VPN)
- Secure connection to on-premises network
- IPSec encryption for data transmission
- Redundant VPN tunnels for high availability

## Security Features
1. Data at Rest:
   - S3 encryption using AES-256
   - Versioning for change tracking
   - Access controls via IAM

2. Data in Transit:
   - HTTPS for all API calls
   - VPN for on-premises connection
   - CloudFront SSL/TLS

3. Authentication:
   - Cognito user pools
   - IAM roles and policies
   - Secure token management

## Cost Optimization
1. Storage:
   - S3 Intelligent-Tiering
   - Lifecycle policies
   - Version cleanup policies

2. Computing:
   - Fargate spot instances
   - Auto-scaling
   - Pay-per-use model

3. Distribution:
   - CloudFront caching
   - Regional data transfer
   - Edge computing optimization

## Data Flow
1. Customer Authentication
   - Customer logs in via Cognito
   - Receives temporary credentials

2. Recipe Upload
   - Authenticated upload to S3
   - Version control maintained

3. Processing
   - AWS Batch processes recipes
   - Creates consolidated archives

4. Distribution
   - CloudFront serves files globally
   - Edge caching improves performance

## Monitoring and Logging
- CloudWatch metrics
- S3 access logs
- VPN connection monitoring
- Batch job statistics 