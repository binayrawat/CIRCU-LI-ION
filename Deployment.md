# VPN Setup Guide

## Basic Overview
A VPN (Virtual Private Network) connection between your office and AWS cloud:
- Creates a secure connection to AWS
- Allows private access to cloud resources
- Helps meet security requirements

## Simple Setup Steps

1. **Gather Information:**
   ```bash
   # You'll need:
   - Your office IP address
   - Your network range
   - AWS region
   ```

2. **Update Configuration:**
   ```hcl
   # In main.tf, remove the /* */ to enable:
   module "network" {
     source        = "../../modules/network"
     environment   = var.environment
     project       = var.project
     customer_ip   = var.customer_ip    
     customer_cidr = var.customer_cidr   
   }
   ```

3. **Add Your Details:**
   ```bash
   # Create a new file named terraform.tfvars:
   customer_ip   = "203.0.113.1"        # Your office IP
   customer_cidr = "192.168.0.0/16"     # Your network range
   ```

4. **Run the Setup:**
   ```bash
   terraform apply
   ```

## Main Components
1. VPC - Your private network in AWS
2. VPN Gateway - The AWS side of the connection
3. Customer Gateway - Your office side of the connection
4. Security Groups - Network security rules

## Basic Monitoring
Check if everything is working:
```bash
# Check VPN status
aws ec2 describe-vpn-connections

# Check if you can reach AWS
ping <private-ip>
```

## Common Problems and Fixes
1. Can't Connect:
   - Check your IP address is correct
   - Verify security groups
   - Ensure network range is correct

2. Connection Drops:
   - Check both VPN tunnels
   - Verify network settings
   - Review security rules

## Costs
Three main costs:
1. VPN connection (hourly rate)
2. Data transfer
3. VPN Gateway (free)

Finally, deployment is straightforward:
1. Simple setup steps
2. VPN configuration
3. Monitoring included

## Version Control Workflow

1. Clone repository:
```bash
git clone https://github.com/your-org/CIRCU-LI-ION.git
cd CIRCU-LI-ION
```

2. Create feature branch:
```bash
git checkout -b feature/your-feature
```

3. Make changes and commit:
```bash
git add .
git commit -m "feat(scope): description"
```

4. Push and create PR:
```bash
git push origin feature/your-feature
# Create PR through GitHub interface
```

5. Review Process:
- Code review required
- Tests must pass
- Documentation updated
- Security reviewed