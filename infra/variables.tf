variable "cluster_service_role" {
  description = "IAM role name to allow the Kubernetes control plane to manage AWS resources"
  type        = string
}

variable "nodegroup_role" {
  description = "IAM role name to use for EKS node group"
  type        = string
}
