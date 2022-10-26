variable "env_name" {
  description = "Name of the environment"
  type        = string
}

variable "cluster_service_role" {
  description = "IAM role name to allow the Kubernetes control plane to manage AWS resources"
  type        = string
}

variable "nodegroup_role" {
  description = "IAM role name to use for EKS node group"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR ranges"
  type        = string
}

variable "vpc_public_subnets" {
  description = "VPC Public subnets for EKS"
  type        = list(string)
}

variable "vpc_private_subnets" {
  description = "VPC Private subnets for EKS"
  type        = list(string)
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.23"
}

variable "cassandra" {
  description = "Cassandra nodes configuration"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    size           = number
  })
  default = {
    instance_types = ["t3.small"]
    max_size       = 3
    min_size       = 0
    size           = 3
  }
}

variable "misc" {
  description = "Nodes configuration for other k8ssandra components"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    size           = number
  })
  default = {
    instance_types = ["t3.small"]
    max_size       = 1
    min_size       = 1
    size           = 1
  }
}
