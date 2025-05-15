output "node_group_name" {
  description = "The name of the EKS node group"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "The ARN of the EKS node group"
  value       = aws_eks_node_group.this.arn
}

output "node_group_id" {
  description = "The ID of the EKS node group"
  value       = aws_eks_node_group.this.id
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.this.status
}

output "node_security_group_id" {
  description = "The ID of the node security group"
  value       = aws_security_group.nodes.id
}