# IAM Role for EBS CSI Driver
data "aws_iam_policy_document" "ebs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [var.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role_policy.json

  tags = merge(var.tags, { Name = "${var.cluster_name}-ebs-csi-driver" })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Additional policy for KMS encryption if enabled
resource "aws_iam_policy" "ebs_csi_kms" {
  count       = var.enable_kms_encryption ? 1 : 0
  name        = "${var.cluster_name}-ebs-csi-kms-policy"
  description = "Policy to allow EBS CSI driver to use KMS keys for encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn != null ? [var.kms_key_arn] : ["*"]
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-ebs-csi-kms-policy" })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_kms" {
  count      = var.enable_kms_encryption ? 1 : 0
  policy_arn = aws_iam_policy.ebs_csi_kms[0].arn
  role       = aws_iam_role.ebs_csi_driver.name
}

# Install EBS CSI Driver as an EKS addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_addon_version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  
  # Add conflict resolution
  resolve_conflicts        = "OVERWRITE"
  
  tags = merge(var.tags, { Name = "${var.cluster_name}-ebs-csi-addon" })
}