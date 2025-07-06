# EKS Cluster Module

This Terraform module creates an Amazon EKS cluster with self-managed node groups for CPU and GPU workloads.

## Features

- **EKS Cluster v1.33** with full logging enabled
- **Self-managed node groups** for maximum control
- **CPU node group** for kube-system pods and general workloads
- **GPU node group** with g5g.16xlarge instances for GPU workloads
- **Proper IAM roles and policies** for EKS and node groups
- **Security groups** configured for EKS communication
- **Auto scaling groups** for both node types
- **Node labeling and tainting** for workload isolation

## Architecture

```
EKS Cluster (v1.33)
├── CPU Node Group (t3.medium)
│   ├── Labels: node.kubernetes.io/instance-type=cpu
│   ├── Taints: dedicated=cpu:NoSchedule
│   └── Purpose: kube-system pods, general workloads
└── GPU Node Group (g5g.16xlarge)
    ├── Labels: node.kubernetes.io/instance-type=gpu,accelerator=nvidia-t4g
    ├── Taints: dedicated=gpu:NoSchedule
    └── Purpose: GPU workloads, ML/AI applications
```

## Usage

```hcl
module "eks" {
  source = "./eks"

  cluster_name = "my-eks-cluster"
  
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids
  
  # CPU Node Group Configuration
  cpu_instance_type        = "t3.medium"
  cpu_node_desired_capacity = 2
  cpu_node_min_size        = 1
  cpu_node_max_size        = 4
  
  # GPU Node Group Configuration
  gpu_instance_type        = "g5g.16xlarge"
  gpu_node_desired_capacity = 2
  gpu_node_min_size        = 2
  gpu_node_max_size        = 4
  
  # Optional: Capacity block for GPU instances
  gpu_capacity_block_id = "cr-1234567890abcdef0"
  
  # Optional: SSH key for node access
  key_name = "my-ssh-key"
  
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
| cluster_name | Name of the EKS cluster | `string` | `"eks-slinky"` | no |
| kubernetes_version | Kubernetes version for the EKS cluster | `string` | `"1.33"` | no |
| vpc_id | VPC ID where the EKS cluster will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| private_subnet_ids | List of private subnet IDs for the node groups | `list(string)` | n/a | yes |
| public_access_cidrs | List of CIDR blocks that can access the EKS cluster API server | `list(string)` | `["0.0.0.0/0"]` | no |
| key_name | Name of the EC2 key pair for SSH access to nodes | `string` | `""` | no |
| cpu_node_ami_id | AMI ID for CPU nodes. If empty, will use the latest EKS-optimized AMI for the specified Kubernetes version | `string` | `""` | no |
| cpu_instance_type | EC2 instance type for CPU nodes | `string` | `"t3.medium"` | no |
| cpu_node_desired_capacity | Desired number of CPU nodes | `number` | `2` | no |
| cpu_node_min_size | Minimum number of CPU nodes | `number` | `1` | no |
| cpu_node_max_size | Maximum number of CPU nodes | `number` | `4` | no |
| gpu_node_ami_id | AMI ID for GPU nodes. If empty, will use the latest EKS-optimized GPU AMI (ARM64) for the specified Kubernetes version | `string` | `""` | no |
| gpu_instance_type | EC2 instance type for GPU nodes | `string` | `"g5g.16xlarge"` | no |
| gpu_node_desired_capacity | Desired number of GPU nodes | `number` | `2` | no |
| gpu_node_min_size | Minimum number of GPU nodes | `number` | `2` | no |
| gpu_node_max_size | Maximum number of GPU nodes | `number` | `4` | no |
| gpu_capacity_block_id | Capacity block ID for GPU instances. If provided, GPU nodes will use this capacity block | `string` | `""` | no |
| common_tags | Common tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the EKS cluster |
| cluster_name | The name of the EKS cluster |
| cluster_endpoint | The endpoint for the EKS cluster |
| cluster_certificate_authority_data | The certificate authority data for the EKS cluster |
| cluster_oidc_issuer_url | The OIDC issuer URL for the EKS cluster |
| cluster_oidc_provider_arn | The OIDC provider ARN for the EKS cluster |
| cluster_role_arn | The ARN of the EKS cluster IAM role |
| node_group_role_arn | The ARN of the EKS node group IAM role |
| cluster_security_group_id | The ID of the EKS cluster security group |
| node_security_group_id | The ID of the EKS node security group |
| cpu_node_launch_template_id | The ID of the CPU node launch template |
| gpu_node_launch_template_id | The ID of the GPU node launch template |
| cpu_node_autoscaling_group_name | The name of the CPU node autoscaling group |
| gpu_node_autoscaling_group_name | The name of the GPU node autoscaling group |
| kubeconfig_command | Command to configure kubectl for the EKS cluster |

## Node Group Details

### CPU Node Group
- **Instance Type**: t3.medium (configurable)
- **Purpose**: Run kube-system pods and general workloads
- **Labels**: `node.kubernetes.io/instance-type=cpu`
- **Taints**: `dedicated=cpu:NoSchedule`
- **Scaling**: 1-4 nodes (configurable)

### GPU Node Group
- **Instance Type**: g5g.16xlarge (configurable)
- **Purpose**: GPU workloads, ML/AI applications
- **Architecture**: ARM64 (AWS Graviton)
- **Labels**: `node.kubernetes.io/instance-type=gpu`, `accelerator=nvidia-t4g`
- **Taints**: `dedicated=gpu:NoSchedule`
- **Scaling**: 2-4 nodes (configurable)

## Connecting to the Cluster

After the cluster is created, configure kubectl:

```bash
# Use the output command
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster --no-cli-pager

# Or manually
aws eks get-token --cluster-name my-eks-cluster --region us-east-1 --no-cli-pager
```

## Workload Scheduling

### For CPU workloads:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-workload
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "cpu"
    effect: "NoSchedule"
  nodeSelector:
    node.kubernetes.io/instance-type: cpu
  containers:
  - name: app
    image: nginx
```

### For GPU workloads:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  nodeSelector:
    node.kubernetes.io/instance-type: gpu
  containers:
  - name: gpu-app
    image: nvidia/cuda:11.0-base
    resources:
      limits:
        nvidia.com/gpu: 1
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Notes

- The module uses self-managed node groups for maximum control
- Nodes are placed in private subnets for security
- CPU nodes use x86_64 EKS-optimized AMIs
- GPU nodes use g5g.16xlarge instances with NVIDIA T4G GPUs and ARM64 EKS-optimized AMIs
- Both node groups have proper taints to prevent unwanted scheduling
- The cluster has full logging enabled for monitoring and debugging
- GPU nodes can optionally use capacity blocks for guaranteed instance availability
- By default, both node groups use the latest EKS-optimized AMIs for the specified Kubernetes version 