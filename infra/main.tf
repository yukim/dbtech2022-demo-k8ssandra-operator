provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  region = "ap-northeast-3"
  alias  = "osaka"
}

module "control-plane" {
  source = "./modules/k8s"

  env_name             = "control-plane"
  cluster_service_role = var.cluster_service_role
  nodegroup_role       = var.nodegroup_role
  cassandra = {
    instance_types = ["t3.small"]
    max_size       = 1
    min_size       = 0
    size           = 0
  }
  misc = {
    instance_types = ["t3.small"]
    max_size       = 3
    min_size       = 0
    size           = 2
  }
  vpc_cidr            = "10.0.0.0/16"
  vpc_public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  vpc_private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

module "dc-tokyo" {
  source = "./modules/k8s"

  env_name             = "dc-tokyo"
  cluster_service_role = var.cluster_service_role
  nodegroup_role       = var.nodegroup_role
  vpc_cidr             = "10.1.0.0/16"
  vpc_public_subnets   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  vpc_private_subnets  = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
}

module "dc-osaka" {
  source = "./modules/k8s"
  providers = {
    aws = aws.osaka
  }

  env_name             = "dc-osaka"
  cluster_service_role = var.cluster_service_role
  nodegroup_role       = var.nodegroup_role
  vpc_cidr             = "10.2.0.0/16"
  vpc_public_subnets   = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  vpc_private_subnets  = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
}
