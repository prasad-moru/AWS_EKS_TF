output "ebs_csi_role_arn" {
  description = "ARN of IAM role for EBS CSI driver"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "ebs_csi_addon_id" {
  description = "ID of the EBS CSI driver EKS addon"
  value       = aws_eks_addon.ebs_csi_driver.id
}