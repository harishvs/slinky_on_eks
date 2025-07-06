# VPC Module for EKS Cluster

This Terraform module creates a VPC with networking components required for an EKS cluster in AWS.

## Features

- VPC with DNS support enabled
- 2 Public subnets across 2 availability zones (us-east-1a, us-east-1b)
- 2 Private subnets across 2 availability zones (us-east-1a, us-east-1b)
- Internet Gateway for public subnets
- NAT Gateway for private subnets
- Proper route tables and associations
- EKS-compatible subnet tagging

## Usage

```hcl
module "vpc" {
  source = "./vpc"

  name_prefix = "my-eks"
  
  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  common_tags = {
    Environment = "production"
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24"]` | no |
| availability_zones | Availability zones for subnets | `list(string)` | `["us-east-1a", "us-east-1b"]` | no |
| name_prefix | Prefix for resource names | `string` | `"eks"` | no |
| common_tags | Common tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of IDs of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| public_subnet_cidrs | List of CIDR blocks of public subnets |
| private_subnet_cidrs | List of CIDR blocks of private subnets |
| availability_zones | List of availability zones used |
| nat_gateway_id | The ID of the NAT Gateway |
| internet_gateway_id | The ID of the Internet Gateway |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Notes

- The module creates a single NAT Gateway in the first public subnet to reduce costs
- Public subnets have `map_public_ip_on_launch` enabled
- Subnets are tagged with EKS-specific tags for load balancer integration
- All resources are tagged with the provided common tags 