data "aws_iam_role" "cluster_service_role" {
  name = var.cluster_service_role
}

data "aws_iam_role" "nodegroup_role" {
  name = var.nodegroup_role
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  # Do not create IAM role
  create_iam_role = false
  iam_role_arn    = data.aws_iam_role.cluster_service_role.arn

  cluster_name    = "eks-${var.env_name}"
  cluster_version = var.eks_cluster_version

  cluster_addons = {
    aws-ebs-csi-driver = {}
    vpc-cni            = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = false

  eks_managed_node_group_defaults = {
    # Do not create IAM role
    create_iam_role                       = false
    iam_role_arn                          = data.aws_iam_role.nodegroup_role.arn
    attach_cluster_primary_security_group = true
  }
  eks_managed_node_groups = {
    # Node group for deploying Cassandra
    ng-cassandra = {
      min_size       = var.cassandra.min_size
      max_size       = var.cassandra.max_size
      desired_size   = var.cassandra.size
      instance_types = var.cassandra.instance_types
      labels = {
        role = "cassandra"
      }
    }
    # Node group for deploying Stargate and reaper
    ng-misc = {
      min_size       = var.misc.min_size
      max_size       = var.misc.max_size
      desired_size   = var.misc.size
      instance_types = var.misc.instance_types
      labels = {
        role = "misc"
      }
    }
  }
}
