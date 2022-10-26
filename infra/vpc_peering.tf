# Control plane --> DC Tokyo
resource "aws_vpc_peering_connection" "control_plane_to_tokyo" {
  vpc_id      = module.control-plane.vpc_id
  peer_vpc_id = module.dc-tokyo.vpc_id
  auto_accept = true
}

# Control plane --> DC Osaka
resource "aws_vpc_peering_connection" "control_plane_to_osaka" {
  vpc_id      = module.control-plane.vpc_id
  peer_vpc_id = module.dc-osaka.vpc_id
  peer_region = "ap-northeast-3"
}

resource "aws_vpc_peering_connection_accepter" "control_plane_to_osaka" {
  vpc_peering_connection_id = aws_vpc_peering_connection.control_plane_to_osaka.id
  provider                  = aws.osaka
  auto_accept               = true
}

# DS Tokyo --> DC Osaka
resource "aws_vpc_peering_connection" "tokyo_to_osaka" {
  vpc_id      = module.dc-tokyo.vpc_id
  peer_vpc_id = module.dc-osaka.vpc_id
  peer_region = "ap-northeast-3"
}

resource "aws_vpc_peering_connection_accepter" "tokyo_to_osaka" {
  vpc_peering_connection_id = aws_vpc_peering_connection.tokyo_to_osaka.id
  provider                  = aws.osaka
  auto_accept               = true
}

# Security Groups
data "aws_security_group" "dc-tokyo-sg" {
  id = module.dc-tokyo.node_security_group_id
}
resource "aws_security_group_rule" "dc-tokyo-sg" {
  security_group_id = data.aws_security_group.dc-tokyo-sg.id
  type              = "ingress"
  description       = "Apache Cassandra management API call from k8ssandra-operator"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [module.control-plane.vpc_cidr_block]
}
resource "aws_security_group_rule" "dc-tokyo-cassandra" {
  security_group_id = data.aws_security_group.dc-tokyo-sg.id
  type              = "ingress"
  description       = "Apache Cassandra cross DC communication"
  from_port         = 7000
  to_port           = 7001
  protocol          = "tcp"
  cidr_blocks       = [module.dc-osaka.vpc_cidr_block]
}

data "aws_security_group" "dc-osaka-sg" {
  provider = aws.osaka
  id       = module.dc-osaka.node_security_group_id
}
resource "aws_security_group_rule" "dc-osaka-sg" {
  provider          = aws.osaka
  security_group_id = data.aws_security_group.dc-osaka-sg.id
  type              = "ingress"
  description       = "Apache Cassandra management API call from k8ssandra-operator"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [module.control-plane.vpc_cidr_block]
}
resource "aws_security_group_rule" "dc-osaka-cassandra" {
  provider          = aws.osaka
  security_group_id = data.aws_security_group.dc-osaka-sg.id
  type              = "ingress"
  description       = "Apache Cassandra cross DC communication"
  from_port         = 7000
  to_port           = 7001
  protocol          = "tcp"
  cidr_blocks       = [module.dc-tokyo.vpc_cidr_block]
}

# Routing tables
data "aws_subnets" "control-plane-private" {
  filter {
    name   = "vpc-id"
    values = [module.control-plane.vpc_id]
  }

  tags = {
    Tier = "Private"
  }
}
data "aws_route_table" "control-plane-private-rt" {
  for_each  = toset(data.aws_subnets.control-plane-private.ids)
  subnet_id = each.key
}
resource "aws_route" "control-plane-to-tokyo" {
  for_each                  = toset([for rt in data.aws_route_table.control-plane-private-rt : rt.id])
  route_table_id            = each.key
  destination_cidr_block    = module.dc-tokyo.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.control_plane_to_tokyo.id
}
resource "aws_route" "control-plane-to-osaka" {
  for_each                  = toset([for rt in data.aws_route_table.control-plane-private-rt : rt.id])
  route_table_id            = each.key
  destination_cidr_block    = module.dc-osaka.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.control_plane_to_osaka.id
}

data "aws_subnets" "dc-tokyo-private" {
  filter {
    name   = "vpc-id"
    values = [module.dc-tokyo.vpc_id]
  }

  tags = {
    Tier = "Private"
  }
}
data "aws_route_table" "dc-tokyo-private-rt" {
  for_each  = toset(data.aws_subnets.dc-tokyo-private.ids)
  subnet_id = each.key
}
resource "aws_route" "tokyo_to_control_plane" {
  for_each                  = toset([for rt in data.aws_route_table.dc-tokyo-private-rt : rt.id])
  route_table_id            = each.key
  destination_cidr_block    = module.control-plane.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.control_plane_to_tokyo.id
}
resource "aws_route" "tokyo-to-osaka" {
  for_each                  = toset([for rt in data.aws_route_table.dc-tokyo-private-rt : rt.id])
  route_table_id            = each.key
  destination_cidr_block    = module.dc-osaka.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.tokyo_to_osaka.id
}


data "aws_subnets" "dc-osaka-private" {
  provider = aws.osaka
  filter {
    name   = "vpc-id"
    values = [module.dc-osaka.vpc_id]
  }

  tags = {
    Tier = "Private"
  }
}
data "aws_route_table" "dc-osaka-private-rt" {
  provider  = aws.osaka
  for_each  = toset(data.aws_subnets.dc-osaka-private.ids)
  subnet_id = each.key
}
resource "aws_route" "osaka_to_control_plane" {
  provider                  = aws.osaka
  for_each                  = toset([for rt in data.aws_route_table.dc-osaka-private-rt : rt.id])
  route_table_id            = each.key
  destination_cidr_block    = module.control-plane.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.control_plane_to_osaka.id
}
resource "aws_route" "osaka-to-tokyo" {
  provider                  = aws.osaka
  for_each                  = toset([for rt in data.aws_route_table.dc-osaka-private-rt : rt.id])
  route_table_id            = each.key
  destination_cidr_block    = module.dc-tokyo.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.tokyo_to_osaka.id
}
