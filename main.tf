# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name            = "${var.project}-${var.environment}"
  cluster_name    = "${local.name}-cluster"
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

# Module: EKS
module "eks" {
  source = "./modules/eks"
  
  depends_on = [module.vpc]

  cluster_name            = local.cluster_name
  cluster_version         = var.eks_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  
  # Node group configuration
  node_group_name         = "${local.name}-nodes"
  node_instance_types     = var.eks_node_instance_types
  node_desired_size       = var.eks_node_desired_size
  node_min_size           = var.eks_node_min_size
  node_max_size           = var.eks_node_max_size
  node_disk_size          = var.eks_node_disk_size
  
  tags                    = local.eks_tags
}

# Module: EBS CSI Driver
module "ebs_csi" {
  source = "./modules/ebs-csi"
  
  depends_on = [module.eks]

  cluster_name            = module.eks.cluster_name
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_provider_url       = module.eks.oidc_provider_url
  ebs_csi_addon_version   = "v1.40.1-eksbuild.1"
}

# Module: ALB Ingress Controller
module "alb_ingress" {
  source = "./modules/alb-ingress"
  count  = var.enable_alb_ingress ? 1 : 0
  
  depends_on = [module.eks, module.ebs_csi]

  cluster_name            = module.eks.cluster_name
  vpc_id                  = module.vpc.vpc_id
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_provider_url       = module.eks.oidc_provider_url
}