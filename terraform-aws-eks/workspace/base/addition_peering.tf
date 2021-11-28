//########################################################################
//# vpc_peering:
//########################################################################
//locals {
//  names = [
//    "tz-devops-utils",
//  ]
//  resources = [
//    "tz-jenkins_${local.cluster_name}",
//  ]
//  route_table_name = [
//    "devops-utils",
//  ]
//  route_table_id = [
//    "rtb-xxxxx",
//  ]
//  peer_vpc_id = [
//    "vpc-xxxxx",
//  ]
//  destination_cidr_block = [
//    "20.10.0.0/16",
//  ]
//}
//
//########################################################################
//# vpc_peering: eks <-> utils
//########################################################################
//resource "aws_vpc_peering_connection" "eks2utils" {
//  count         = length(local.names)
//  peer_vpc_id   = element(local.peer_vpc_id.*, count.index)
//  vpc_id        = module.vpc.vpc_id
//  auto_accept   = true
//  accepter {
//    allow_remote_vpc_dns_resolution = true
//  }
//  requester {
//    allow_remote_vpc_dns_resolution = true
//  }
//  tags = {
//    Name = element(local.resources.*, count.index)
//  }
//}
//resource "aws_route" "eks2utils" {
//  count         = length(local.names)
//  route_table_id            = module.vpc.private_route_table_ids[0]   # eks
//  destination_cidr_block    = element(local.destination_cidr_block.*, count.index)
//  vpc_peering_connection_id = element(aws_vpc_peering_connection.eks2utils.*.id, count.index)
//}
//resource "aws_route" "utils2eks" {
//  count         = length(local.names)
//  route_table_id            = element(local.route_table_id.*, count.index)
//  destination_cidr_block    = local.VPC_CIDR   # eks
//  vpc_peering_connection_id = element(aws_vpc_peering_connection.eks2utils.*.id, count.index)
//}
//
