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

# Module: EKS - using pre-created IAM roles
module "eks" {
  source = "./modules/eks"
  
  depends_on = [
    module.vpc,
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController
  ]

  cluster_name            = local.cluster_name
  cluster_version         = var.eks_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  cluster_role_arn        = aws_iam_role.cluster.arn  # Use directly created role
  # Node security group will be linked later
  enable_core_addons     = false
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

# Module: Node Group - use the pre-created IAM role
module "node_group" {
  source = "./modules/node-group"
  
  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonSSMManagedInstanceCore
  ]

  cluster_name            = module.eks.cluster_name
  node_group_name         = local.node_group_name
  node_role_arn           = aws_iam_role.node.arn  # Use directly created role
  subnet_ids              = module.vpc.private_subnet_ids
  vpc_id                  = module.vpc.vpc_id
  cluster_security_group_id = module.eks.cluster_security_group_id
  
  # Node group configuration
  desired_size            = var.eks_node_desired_size
  min_size                = var.eks_node_min_size
  max_size                = var.eks_node_max_size
  disk_size               = var.eks_node_disk_size
  instance_types          = var.eks_node_instance_types
  
  tags                    = local.eks_tags
}

# Link the cluster to the node group security group
resource "aws_security_group_rule" "cluster_to_nodes" {
  description              = "Allow cluster control plane to communicate with worker nodes"
  security_group_id        = module.eks.cluster_security_group_id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.node_group.node_security_group_id
  
  depends_on = [module.eks, module.node_group]
}

# Module: EBS CSI Driver - now using the OIDC provider we just created
module "ebs_csi" {
  source = "./modules/ebs-csi"
  
  depends_on = [module.eks, aws_iam_openid_connect_provider.eks]

  cluster_name            = module.eks.cluster_name
  oidc_provider_arn       = aws_iam_openid_connect_provider.eks.arn
  oidc_provider_url       = aws_iam_openid_connect_provider.eks.url
  ebs_csi_addon_version   = "v1.40.1-eksbuild.1"
}

# Module: ALB Ingress Controller - now using the OIDC provider we just created
module "alb_ingress" {
  source = "./modules/alb-ingress"
  count  = var.enable_alb_ingress ? 1 : 0
  
  depends_on = [module.eks, aws_iam_openid_connect_provider.eks]

  cluster_name            = module.eks.cluster_name
  vpc_id                  = module.vpc.vpc_id
  oidc_provider_arn       = aws_iam_openid_connect_provider.eks.arn
  oidc_provider_url       = aws_iam_openid_connect_provider.eks.url
}