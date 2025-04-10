# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name            = "${var.project}-${var.environment}"
  cluster_name    = "${local.name}-cluster"
  node_group_name = "${local.name}-nodes"
  vpc_tags        = merge(var.additional_tags, { Name = "${local.name}-vpc" })
  eks_tags        = merge(var.additional_tags, { Name = "${local.name}-eks" })
  azs             = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)
}

# Create cluster IAM role - this breaks the circular dependency
resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.eks_tags,
    {
      Name = "${local.cluster_name}-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# Create Node IAM role - this breaks the circular dependency
resource "aws_iam_role" "node" {
  name = "${local.node_group_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.eks_tags,
    {
      Name = "${local.node_group_name}-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# Optional CloudWatch monitoring policy
resource "aws_iam_role_policy_attachment" "node_CloudWatchAgentServerPolicy" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node.name
}

# Module: VPC
module "vpc" {
  source = "./modules/vpc"

  name                     = local.name
  cidr                     = var.vpc_cidr
  azs                      = local.azs
  subnet_cidr_bits         = var.subnet_cidr_bits
  cluster_name             = local.cluster_name
  tags                     = local.vpc_tags
}

# Create node security group first
resource "aws_security_group" "nodes" {
  name        = "${local.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    local.eks_tags,
    {
      Name = "${local.cluster_name}-node-sg"
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  security_group_id        = aws_security_group.nodes.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "nodes_outbound" {
  security_group_id = aws_security_group.nodes.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Module: EKS - using pre-created IAM roles and security group
module "eks" {
  source = "./modules/eks"
  
  depends_on = [
    module.vpc,
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_security_group.nodes
  ]

  cluster_name            = local.cluster_name
  cluster_version         = var.eks_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  cluster_role_arn        = aws_iam_role.cluster.arn
  node_security_group_id  = aws_security_group.nodes.id
  enable_core_addons      = false
  tags                    = local.eks_tags
}

# Now create OIDC provider based on the cluster
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_identity_oidc_issuer

  tags = merge(
    local.eks_tags,
    {
      Name = "${local.cluster_name}-eks-oidc"
    }
  )
}

data "tls_certificate" "eks" {
  url = module.eks.cluster_identity_oidc_issuer
  depends_on = [module.eks]
}

# Connect the cluster security group to node security group
resource "aws_security_group_rule" "cluster_to_nodes" {
  description              = "Allow cluster control plane to communicate with worker nodes"
  security_group_id        = module.eks.cluster_security_group_id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  depends_on               = [module.eks]
}

resource "aws_security_group_rule" "nodes_cluster_inbound" {
  description              = "Allow worker nodes to receive communication from cluster control plane"
  security_group_id        = aws_security_group.nodes.id
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_security_group_id
  depends_on               = [module.eks]
}

# Create launch template for node group
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${local.node_group_name}-"
  description = "Launch template for EKS node group"

  # Use custom block device mappings to improve performance
  block_device_mappings {
    device_name = "/dev/xvda"
    
    ebs {
      volume_size           = var.eks_node_disk_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.eks_tags,
      {
        Name = "${local.node_group_name}-node"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.eks_tags,
      {
        Name = "${local.node_group_name}-volume"
      }
    )
  }

  tags = merge(
    local.eks_tags,
    {
      Name = "${local.node_group_name}-launch-template"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Create node group with the pre-created resources
resource "aws_eks_node_group" "this" {
  cluster_name    = module.eks.cluster_name
  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.vpc.private_subnet_ids

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = var.eks_node_instance_types

  # Use launch template for disk size
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonSSMManagedInstanceCore,
    aws_security_group_rule.nodes_cluster_inbound
  ]

  tags = merge(
    local.eks_tags,
    {
      Name = local.node_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Module: EBS CSI Driver - now using the OIDC provider we just created
module "ebs_csi" {
  source = "./modules/ebs-csi"
  
  depends_on = [module.eks, aws_iam_openid_connect_provider.eks, aws_eks_node_group.this]

  cluster_name            = module.eks.cluster_name
  oidc_provider_arn       = aws_iam_openid_connect_provider.eks.arn
  oidc_provider_url       = aws_iam_openid_connect_provider.eks.url
}

# Module: ALB Ingress Controller - now using the OIDC provider we just created
module "alb_ingress" {
  source = "./modules/alb-ingress"
  count  = var.enable_alb_ingress ? 1 : 0
  
  depends_on = [module.eks, aws_iam_openid_connect_provider.eks, aws_eks_node_group.this]

  cluster_name            = module.eks.cluster_name
  vpc_id                  = module.vpc.vpc_id
  oidc_provider_arn       = aws_iam_openid_connect_provider.eks.arn
  oidc_provider_url       = aws_iam_openid_connect_provider.eks.url
}