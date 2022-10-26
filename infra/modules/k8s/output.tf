output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = "eks-${var.env_name}"
}

output "vpc_id" {
  description = "VPC ID associated for EKS cluster"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR"
  value       = module.vpc.vpc_cidr_block
}

output "subnet_ids" {
  description = "Private Subnet Ids"
  value       = module.vpc.private_subnets
}

output "node_security_group_id" {
  description = "Node group's security groups"
  value       = module.eks.node_security_group_id
}
