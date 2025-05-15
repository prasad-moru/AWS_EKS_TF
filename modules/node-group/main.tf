# EKS Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  //disk_size      = var.disk_size
  instance_types = var.instance_types

  # Use launch template for additional customization
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  tags = merge(
    var.tags,
    {
      Name = var.node_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Launch template for node group
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.node_group_name}-"
  description = "Launch template for EKS node group"

  # Use custom block device mappings to improve performance
  block_device_mappings {
    device_name = "/dev/xvda"
    
    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.node_group_name}-node"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.node_group_name}-volume"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.node_group_name}-launch-template"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Node Group Security Group
resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
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

resource "aws_security_group_rule" "nodes_cluster_inbound" {
  description              = "Allow worker nodes to receive communication from cluster control plane"
  security_group_id        = aws_security_group.nodes.id
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = var.cluster_security_group_id
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