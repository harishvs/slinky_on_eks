variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-slinky"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (both public and private)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the node groups"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster API server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access to nodes"
  type        = string
  default     = ""
}

# CPU Node Group Variables
variable "cpu_node_ami_id" {
  description = "AMI ID for CPU nodes. If empty, will use the latest EKS-optimized AMI for the specified Kubernetes version"
  type        = string
  default     = ""
}

variable "cpu_instance_type" {
  description = "EC2 instance type for CPU nodes"
  type        = string
  default     = "t3.medium"
}

variable "cpu_node_desired_capacity" {
  description = "Desired number of CPU nodes"
  type        = number
  default     = 2
}

variable "cpu_node_min_size" {
  description = "Minimum number of CPU nodes"
  type        = number
  default     = 1
}

variable "cpu_node_max_size" {
  description = "Maximum number of CPU nodes"
  type        = number
  default     = 4
}

# GPU Node Group Variables
variable "gpu_node_ami_id" {
  description = "AMI ID for GPU nodes. If empty, will use the latest EKS-optimized GPU AMI (ARM64) for the specified Kubernetes version"
  type        = string
  default     = ""
}

variable "gpu_instance_type" {
  description = "EC2 instance type for GPU nodes"
  type        = string
  default     = "g5g.16xlarge"
}

variable "gpu_node_desired_capacity" {
  description = "Desired number of GPU nodes"
  type        = number
  default     = 2
}

variable "gpu_node_min_size" {
  description = "Minimum number of GPU nodes"
  type        = number
  default     = 2
}

variable "gpu_node_max_size" {
  description = "Maximum number of GPU nodes"
  type        = number
  default     = 4
}

variable "gpu_capacity_block_id" {
  description = "Capacity block ID for GPU instances. If provided, GPU nodes will use this capacity block."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "eks-slinky"
    ManagedBy   = "terraform"
  }
} 