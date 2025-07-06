# Main Terraform configuration for EKS Slinky
# This file creates a VPC and EKS cluster with self-managed node groups

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Use the VPC module
module "vpc" {
  source = "./vpc"

  name_prefix = "eks-slinky"
  
  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  common_tags = {
    Environment = "production"
    Project     = "eks-slinky"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}

# Use the EKS module
module "eks" {
  source = "./eks"

  cluster_name = "eks-slinky"
  
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids
  
  # CPU Node Group Configuration (for kube-system pods)
  cpu_instance_type        = "t3.medium"
  cpu_node_desired_capacity = 2
  cpu_node_min_size        = 1
  cpu_node_max_size        = 4
  
  # GPU Node Group Configuration (g5g.16xlarge instances)
  gpu_instance_type        = "g5g.16xlarge"
  gpu_node_desired_capacity = 2
  gpu_node_min_size        = 2
  gpu_node_max_size        = 4
  
  common_tags = {
    Environment = "production"
    Project     = "eks-slinky"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# EKS Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = module.eks.kubeconfig_command
} 