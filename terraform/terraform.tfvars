# Environment
environment = "dev"

# Region
aws_region = "us-west-2"  # Verified: This is your region

# Network details (from your AWS account)
vpc_id            = "vpc-06d3de7767f381fce"  # Verified: Your VPC
subnet_id         = "subnet-0c9b1355e5d272039"  # Verified: Your subnet
security_group_id = "sg-0dcb860c468e82c77"  # Verified: Your security group

# AWS Account ID
account_id = "202533497212"  # Verified: Your AWS account

# Storage
bucket_name_prefix = "circu-li-ion"

# Batch compute settings (standard settings)
batch_max_vcpus = 16
batch_memory    = 16384  # 16GB
batch_vcpus     = 4

customer_ip       = "XX.XX.XX.XX"  # Replace with your VPN endpoint IP 