# CIRCU LI-ION Architecture
=========================

                     ┌──────────────┐
                     │   Internet   │
                     └──────┬───────┘
                            │
                            ▼
┌──────────┐         ┌──────────────┐         ┌──────────┐
│          │         │  CloudFront  │         │          │
│ Customers│◄───────►│ Distribution │◄───────►│ Global   │
│          │   HTTPS │              │         │ Access   │
└──────────┘         └──────┬───────┘         └──────────┘
                            │
                            ▼
┌──────────┐         ┌──────────────┐         ┌──────────┐
│          │   VPN   │  S3 Bucket   │         │ Lambda   │
│On-Premise│◄───────►│  Versioned   │───────►│ Function │
│          │         │              │         │          │
└──────────┘         └──────────────┘         └──────────┘


Component Details:
================

1. CUSTOMER ACCESS
   - Global distribution via CloudFront
   - HTTPS encryption
   - Caching enabled

2. STORAGE (S3)
   - Versioning enabled
   - Encryption at rest
   - Lifecycle policies
   - Access controls

3. PROCESSING (Lambda)
   - Automatic triggering
   - File consolidation
   - ZIP creation
   - Error handling

4. SECURITY
   - VPN connection
   - IAM roles
   - Encryption in transit
   - Network security


Data Flow:
=========

1. Upload Flow:
   On-Premise ──► VPN ──► S3 Bucket

2. Processing Flow:
   S3 Bucket ──► Lambda ──► S3 Bucket (Processed)

3. Distribution Flow:
   S3 Bucket ──► CloudFront ──► Customers


Security Measures:
================

1. Network Security:
   - VPN encryption
   - HTTPS everywhere
   - Private subnets

2. Data Security:
   - S3 encryption
   - IAM policies
   - Access logging

3. Monitoring:
   - CloudWatch
   - CloudTrail
   - S3 access logs 