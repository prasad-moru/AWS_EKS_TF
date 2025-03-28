output "alb_ingress_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_lb_controller.arn
}

output "alb_ingress_policy_arn" {
  description = "ARN of IAM policy for AWS Load Balancer Controller"
  value       = aws_iam_policy.aws_lb_controller.arn
}

output "alb_ingress_helm_release_name" {
  description = "Name of the Helm release for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.name
}

output "alb_ingress_helm_release_version" {
  description = "Version of the Helm chart for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.version
}