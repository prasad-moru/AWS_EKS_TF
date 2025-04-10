# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Add this to locals
locals {
  name            = "${var.project}-${var.environment}"
  cluster_name    = "${local.name}-cluster"
  node_group_name = "${local.name}-nodes"  # Add this line
  vpc_tags        = merge(var.additional_tags, { Name = "${local.name}-vpc" })
  eks_tags        = merge(var.additional_tags, { Name = "${local.name}-eks" })
  azs             = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)
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

# Module: IAM (Add this new module)
module "iam" {
  source = "./modules/iam"
  
  cluster_name               = local.cluster_name
  node_group_name            = local.node_group_name
  cluster_identity_oidc_issuer = module.eks.cluster_identity_oidc_issuer
  enable_cloudwatch_agent    = var.enable_cloudwatch_agent
  tags                       = local.eks_tags
  
  depends_on = [module.eks]
}

# Module: EKS
module "eks" {
  source = "./modules/eks"
  
  depends_on = [module.vpc]

  cluster_name            = local.cluster_name
  cluster_version         = var.eks_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  cluster_role_arn        = module.iam.cluster_role_arn
  node_security_group_id  = module.node_group.node_security_group_id
  
  tags                    = local.eks_tags
}

# Module: Node Group 
module "node_group" {
  source = "./modules/node-group"
  
  depends_on = [module.eks, module.iam]

  cluster_name            = module.eks.cluster_name
  node_group_name         = local.node_group_name
  node_role_arn           = module.iam.node_role_arn
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

# Module: EBS CSI Driver
module "ebs_csi" {
  source = "./modules/ebs-csi"
  
  depends_on = [module.eks, module.iam]

  cluster_name            = module.eks.cluster_name
  oidc_provider_arn       = module.iam.oidc_provider_arn
  oidc_provider_url       = module.iam.oidc_provider_url
  ebs_csi_addon_version   = "v1.40.1-eksbuild.1"
}

# Module: ALB Ingress Controller
module "alb_ingress" {
  source = "./modules/alb-ingress"
  count  = var.enable_alb_ingress ? 1 : 0
  
  depends_on = [module.eks, module.ebs_csi]

  cluster_name            = module.eks.cluster_name
  vpc_id                  = module.vpc.vpc_id
  oidc_provider_arn       = module.iam.oidc_provider_arn
  oidc_provider_url       = module.iam.oidc_provider_url
}