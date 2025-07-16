# GPU Node User Data Script

This directory contains a custom user data script for EKS GPU nodes based on the [AWS re:Post article about custom user data with AL2023 EKS nodes](https://repost.aws/knowledge-center/custom-user-eks-2023).

## Overview

The `gpu-userdata.sh` script is designed to be used with EKS GPU nodes running Amazon Linux 2023 (AL2023) with ARM64 architecture and NVIDIA GPUs. It follows the [AWS re:Post guidelines](https://repost.aws/knowledge-center/custom-user-eks-2023) for custom user data with AL2023 EKS nodes, which uses the **nodeadm** node initialization process with a YAML configuration schema.

The script includes:
- **nodeadm YAML configuration** for EKS node initialization (required for AL2023)
- **GPU-specific setup** for NVIDIA drivers and container runtime
- **Kubernetes integration** with proper node labeling and taints

## Features

### 1. NVIDIA Driver Configuration
- Configures NVIDIA drivers and CUDA support (already included in EKS AMI)
- Sets up NVIDIA container runtime (already included in EKS AMI)
- Ensures NVIDIA persistence daemon is running

### 2. Container Runtime Configuration
- Ensures containerd is properly configured for NVIDIA runtime support (already configured in EKS AMI)
- Sets up GPU monitoring services
- Configures additional utilities and tools

### 3. System Optimizations
- Configures kernel parameters for GPU workloads
- Sets up system limits for memory and stack
- Optimizes for high-performance GPU computing

### 4. Monitoring and Health Checks
- Creates GPU monitoring scripts
- Sets up automated health checks every 5 minutes
- Configures log rotation for GPU-related logs
- Provides GPU information and status monitoring

### 5. Kubernetes Integration
- Automatically labels nodes with GPU-specific labels via nodeadm configuration
- Sets up GPU count detection
- Configures node labels and taints for GPU scheduling
- Uses AL2023 nodeadm YAML schema for proper EKS node initialization

## Usage

The script is automatically applied to GPU nodes through the EKS module configuration in `main.tf`. The GPU node group is configured to use this user data script with proper variable substitution:

```hcl
gpu = {
  # ... other configuration ...
  
  # Custom user data for GPU setup
  user_data = base64encode(templatefile("${path.module}/gpu-userdata.sh", {
    cluster_name = var.cluster_name
    cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = data.aws_eks_cluster.cluster.certificate_authority[0].data
    service_cidr = "10.100.0.0/16"
  }))
  
  # ... rest of configuration ...
}
```

The script uses the MIME multipart format required by AL2023, with:
1. **nodeadm YAML configuration** for EKS node initialization
2. **Shell script** for GPU-specific setup and configuration

## Node Labels and Taints Applied

The script automatically applies the following labels and taints to GPU nodes via the nodeadm configuration:

### Labels
- `nvidia.com/gpu=true` - Indicates the node has NVIDIA GPUs
- `accelerator=nvidia` - Specifies the accelerator type
- `node.kubernetes.io/instance-type=gpu` - Custom instance type label

### Taints
- `nvidia.com/gpu=true:NoSchedule` - Prevents non-GPU workloads from scheduling on GPU nodes

### Additional Labels (applied by shell script)
- `nvidia.com/gpu.count=<count>` - Number of GPUs on the node (detected dynamically)

## Monitoring and Debugging

### Log Files
- `/var/log/user-data.log` - Main user data execution log
- `/var/log/gpu-health.log` - GPU health check logs
- `/var/log/nvidia-*.log` - NVIDIA driver and runtime logs

### Health Check Scripts
- `/usr/local/bin/gpu-health-check.sh` - Manual GPU health check
- `/usr/local/bin/gpu-monitor.sh` - GPU information and monitoring

### Systemd Services
- `nvidia-docker-monitor.service` - GPU monitoring service
- `setup-gpu-labels.service` - Kubernetes node labeling service

## Verification

After the nodes are provisioned, you can verify the setup:

1. **Check GPU availability:**
   ```bash
   kubectl get nodes -l nvidia.com/gpu=true
   ```

2. **Verify GPU drivers:**
   ```bash
   kubectl exec -it <gpu-pod> -- nvidia-smi
   ```

3. **Check node labels:**
   ```bash
   kubectl describe node <gpu-node-name>
   ```

4. **Test GPU workload:**
   ```bash
   kubectl run gpu-test --image=nvidia/cuda:11.8-base-ubuntu20.04 --rm -it --restart=Never -- nvidia-smi
   ```

## Requirements

- EKS cluster with AL2023 ARM64 NVIDIA AMI (`AL2023_ARM_64_NVIDIA`)
- GPU instances (e.g., g5g.16xlarge)
- Proper IAM roles and security groups configured
- Network access for additional package installation

**Note:** The EKS-optimized AMI for AL2023 with NVIDIA support already includes:
- NVIDIA drivers and CUDA support
- NVIDIA container runtime
- containerd configuration for GPU support
- Basic GPU monitoring tools

## AL2023 nodeadm Configuration

The user data script follows the AL2023 nodeadm requirements as specified in the [AWS re:Post article](https://repost.aws/knowledge-center/custom-user-eks-2023):

### Required Parameters
- `cluster.name` - EKS cluster name
- `cluster.apiServerEndpoint` - EKS API server endpoint
- `cluster.certificateAuthority` - EKS cluster CA certificate
- `cluster.cidr` - EKS service CIDR range

### MIME Multipart Format
The script uses the MIME multipart format required by AL2023:
```
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws
[NodeConfig YAML]

--BOUNDARY
Content-Type: text/x-shellscript
[Shell script content]

--BOUNDARY--
```

## Troubleshooting

### Common Issues

1. **NVIDIA drivers not loading:**
   - Check `/var/log/user-data.log` for configuration errors
   - Verify AMI type is `AL2023_ARM_64_NVIDIA`
   - Drivers are pre-installed in the EKS AMI

2. **GPU not visible in containers:**
   - Containerd is pre-configured for GPU support in the EKS AMI
   - Check if NVIDIA modules are loaded: `lsmod | grep nvidia`
   - Verify GPU is detected: `nvidia-smi`

3. **Node labels not applied:**
   - Check `setup-gpu-labels.service` status
   - Verify kubelet is running and accessible

### Debug Commands

```bash
# Check user data execution
sudo cat /var/log/user-data.log

# Check GPU health
sudo /usr/local/bin/gpu-health-check.sh

# Check NVIDIA drivers
nvidia-smi

# Check containerd configuration
sudo cat /etc/containerd/config.toml

# Check systemd services
sudo systemctl status nvidia-docker-monitor.service
sudo systemctl status setup-gpu-labels.service
```

## Security Considerations

- The script runs with root privileges during node initialization
- GPU monitoring services are enabled by default
- Log files may contain sensitive information
- Consider implementing additional security measures for production use

## Customization

You can modify the `gpu-userdata.sh` script to:
- Add additional packages or configurations
- Modify monitoring intervals
- Change GPU-specific settings
- Add custom health checks

Remember to test changes in a non-production environment first. 