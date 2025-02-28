Project Structure

CIRCU-LI-ION/
├── .github/workflows/    # CI/CD configurations
├── backup_$/            # Backup directory
├── recipe-automation/   # Main application code
├── build.sh            # Build script
├── generate_large_recipe.py  # Test file generator
├── requirements.txt    # Python dependencies
├── response.json      # Sample response
├── test-recipe.json   # Test data
└── test.txt          # Test file

Technology Stack

Languages:
├── Python (51.7%)
├── HCL - HashiCorp Configuration Language (47.3%)
└── Shell (1.0%)

AWS Services:
├── Lambda
├── Step Functions
├── S3
├── CloudFront
├── CloudWatch
└── IAM

Core Features Implemented

A. File Processing
├── Upload Detection
├── Size-based Processing
└── Parallel Processing

B. Security
├── VPN Access
├── IAM Roles
└── KMS Encryption

C. Distribution
├── CloudFront
└── S3 Static Hosting



file processing work

1. User uploads file to S3
2. Size check:
   - Small files (<5MB): Direct processing
   - Large files (>5MB): Split and parallel process
3. Results merged and archived
4. Made available via CloudFront

Handle large files

1. split-file-lambda splits into 1MB chunks
2. Parallel processing using Step Functions Map state
3. merge-results-lambda combines processed chunks
4. Efficient resource utilization

Security implementation

1. VPC with public/private subnets
2. Client VPN for secure access
3. IAM roles for least privilege
4. KMS for data encryption
5. CloudFront security headers

handle errors
1. Step Functions error handling
2. CloudWatch logging
3. Retry mechanisms
4. Alert notifications

cost optimization
1. Lambda memory optimization
2. S3 lifecycle rules
3. CloudFront caching
4. Resource cleanup
5. Monitoring and alerts

Key Python Libraries Used
boto3          # AWS SDK
json           # JSON processing
logging        # Logging functionality
datetime       # Time handling
zipfile        # File compression
os             # OS operations

Ensure data consistency
1. S3 versioning
2. Transaction logs
3. Checksum validation
4. State management in Step Functions

Monitor the system
1. CloudWatch metrics
2. Custom dashboards
3. Alert thresholds
4. Log analysis

CI/CD pipeline
1. GitHub Actions workflows
2. Automated testing
3. Infrastructure as Code
4. CI/CD for testing and deployment
