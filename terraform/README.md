# EKS Slinky Terraform Infrastructure

This directory contains the Terraform configuration for the EKS Slinky infrastructure.

## Modules

### VPC Module (`./vpc/`)
- Creates a VPC with networking components required for an EKS cluster
- 2 Public subnets across 2 availability zones (us-east-1a, us-east-1b)
- 2 Private subnets across 2 availability zones (us-east-1a, us-east-1b)
- Internet Gateway for public subnets
- NAT Gateway for private subnets
- Proper route tables and associations
- EKS-compatible subnet tagging

### EKS Module (`./eks/`)
- Creates an EKS cluster with Kubernetes version 1.33
- Self-managed node groups for maximum control
- CPU node group (t3.medium) for kube-system pods and general workloads
- GPU node group (g5g.16xlarge) for GPU workloads and ML/AI applications
- Proper IAM roles, security groups, and auto-scaling configuration
- Node labeling and tainting for workload isolation

## Usage

See `main.tf` for the main Terraform configuration that creates both the VPC and EKS cluster with self-managed node groups.

1. **Initialize Terraform**
   ```sh
   terraform init
   ```

2. **Apply and Cleanup**
   Use the provided script to apply your Terraform changes and then clean up the EKS Access Entry for your user:
   ```sh
   chmod +x apply-and-cleanup.sh delete-eks-access-entry.sh
   ./apply-and-cleanup.sh
   ```
   This will:
   - Run `terraform apply -auto-approve`
   - Delete the EKS Access Entry and policy association for your IAM user (so that only `aws-auth` is used for RBAC)

3. **Manual Cleanup (if needed)**
   You can run the cleanup script separately at any time:
   ```sh
   ./delete-eks-access-entry.sh
   ```

---

**Note:**
- The cleanup step is required because EKS Access Entries and `aws-auth` ConfigMap can conflict. This ensures your access is managed only by `aws-auth`.

## TODO

- [ ] Add IPv6 support to VPC module
  - Enable IPv6 CIDR block on VPC
  - Add IPv6 CIDR blocks to subnets
  - Configure IPv6 route tables
  - Update NAT Gateway configuration for IPv6
  - Add IPv6-specific outputs
- [ ] Enhance backend security
  - Add bucket policy for additional access control
  - Configure CloudTrail for S3 bucket access logging
  - Add tags to backend resources

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- AWS CLI configured with appropriate credentials

## Getting Started

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed

### Setup Backend (First Time Only)

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Set up the S3 backend infrastructure:
   ```bash
   ./setup-backend.sh
   ```

3. Initialize Terraform with the S3 backend:
   ```bash
   terraform init
   ```

### Deploy Infrastructure

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

### Backend Configuration

The project uses S3 as the Terraform backend with the following configuration:
- **S3 Bucket**: `eks-slinky-terraform-state`
- **DynamoDB Table**: `eks-slinky-terraform-locks` (for state locking)
- **Region**: `us-east-1`
- **Encryption**: Enabled
- **Versioning**: Enabled
- **Public Access**: Blocked

## Structure

```
terraform/
├── README.md          # This file
├── main.tf           # Main Terraform configuration
├── backend.tf        # S3 backend configuration
├── setup-backend.sh  # Backend infrastructure setup script
├── vpc/              # VPC module
│   ├── main.tf       # Main VPC configuration
│   ├── variables.tf  # Input variables
│   ├── outputs.tf    # Output values
│   ├── versions.tf   # Version requirements
│   └── README.md     # VPC module documentation
└── eks/              # EKS module
    ├── main.tf       # Main EKS configuration
    ├── node-groups.tf # Node groups configuration
    ├── user-data.sh  # Node bootstrap script
    ├── variables.tf  # Input variables
    ├── outputs.tf    # Output values
    ├── versions.tf   # Version requirements
    └── README.md     # EKS module documentation
``` 