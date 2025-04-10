# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.cluster.id]
  }

  # Add-ons are managed separately below, not directly in the cluster resource

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups
  lifecycle {
    create_before_destroy = true
  }
}

# Create EKS add-ons as separate resources instead of inline with the cluster
resource "aws_eks_addon" "coredns" {
  count = var.enable_core_addons ? 1 : 0
  
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_core_addons ? 1 : 0
  
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_core_addons ? 1 : 0
  
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"
}

# Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
    }
  )
}

resource "aws_security_group_rule" "cluster_egress" {
  security_group_id = aws_security_group.cluster.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "cluster_ingress_https" {
  security_group_id = aws_security_group.cluster.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS access to cluster API server"
}