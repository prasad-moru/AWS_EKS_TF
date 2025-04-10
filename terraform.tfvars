aws_access_key = " "
aws_secret_key = " "

region                   = "us-east-1"
availability_zones_count = 2
project                  = "TFEKSWorkshop"
environment              = "dev"

vpc_cidr         = "10.0.0.0/16"
subnet_cidr_bits = 8

eks_version           = "1.29"
eks_node_instance_types = ["t3.medium"]
eks_node_desired_size = 2
eks_node_min_size     = 1
eks_node_max_size     = 4
eks_node_disk_size    = 20

enable_alb_ingress = true

default_tags = {
  "Project"     = "TFEKSWorkshop"
  "Environment" = "Development"
  "Terraform"   = "true"
  "Owner"       = "DevOps"
}