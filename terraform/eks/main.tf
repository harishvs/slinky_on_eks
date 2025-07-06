module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Self-managed node groups
  eks_managed_node_groups = {}

  # Self-managed node groups for CPU and GPU
  self_managed_node_groups = {
    cpu = {
      name = "cpu-nodes"

      instance_type = "t3.medium"
      min_size      = 2
      max_size      = 4
      desired_size  = 2

      ami_type = "AL2023_x86_64_STANDARD"

      # Use launch template
      use_mixed_instances_policy = false
      create_launch_template     = true
      launch_template_name       = "eks-${var.cluster_name}-cpu-nodes"

      # IAM role
      iam_role_use_name_prefix = false
      iam_role_name            = "${var.cluster_name}-cpu-node-group-role"

      # Security groups
      vpc_security_group_ids = [aws_security_group.eks_nodes.id]

      # Tags
      tags = merge(
        var.common_tags,
        {
          "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/instance-type" = "cpu"
        }
      )
    }

    gpu = {
      name = "gpu-nodes"

      instance_type = "g5g.16xlarge"
      min_size      = 1
      max_size      = 3
      desired_size  = 1

      ami_type = "AL2023_ARM_64_NVIDIA"

      # Use launch template
      use_mixed_instances_policy = false
      create_launch_template     = true
      launch_template_name       = "eks-${var.cluster_name}-gpu-nodes"

      # IAM role
      iam_role_use_name_prefix = false
      iam_role_name            = "${var.cluster_name}-gpu-node-group-role"

      # Security groups
      vpc_security_group_ids = [aws_security_group.eks_nodes.id]

      # Tags
      tags = merge(
        var.common_tags,
        {
          "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/instance-type" = "gpu"
        }
      )
    }
  }

  # Cluster security group
  cluster_security_group_additional_rules = {
    ingress_nodes_443 = {
      description                = "Node groups to cluster API"
      protocol                  = "tcp"
      from_port                 = 443
      to_port                   = 443
      type                      = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  tags = var.common_tags
}

# Security Group for EKS Nodes (simplified, the module handles most of it)
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-nodes-sg"
    }
  )
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Bootstrap EKS Access Entry for cluster creator
resource "aws_eks_access_entry" "admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# EKS cluster auth data source
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# aws-auth ConfigMap for EKS RBAC
resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = data.aws_caller_identity.current.arn
        username = "harishrao"
        groups   = ["system:masters"]
      }
    ])
    mapRoles = yamlencode([
      {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-slinky-cpu-node-group-role"
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-slinky-gpu-node-group-role"
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }

  depends_on = [
    module.eks,
    aws_eks_access_entry.admin,
    aws_eks_access_policy_association.admin
  ]
} 