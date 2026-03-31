output "resource_group_id" {
  description = "Resolved resource group ID."
  value       = data.ibm_resource_group.rg.id
}

output "vpc_id" {
  description = "Dedicated egress VPC ID."
  value       = ibm_is_vpc.egress.id
}

output "vpc_crn" {
  description = "Dedicated egress VPC CRN."
  value       = ibm_is_vpc.egress.crn
}

output "subnet_id" {
  description = "Subnet ID hosting the private NLB."
  value       = ibm_is_subnet.egress.id
}

output "public_gateway_id" {
  description = "Public gateway attached to the NLB subnet for internet egress."
  value       = ibm_is_public_gateway.egress.id
}

output "default_security_group_id" {
  description = "Default VPC security group used by the NLB."
  value       = ibm_is_vpc.egress.default_security_group
}

output "nlb_id" {
  description = "Private NLB ID."
  value       = ibm_is_lb.egress.id
}

output "nlb_hostname" {
  description = "Private NLB hostname."
  value       = ibm_is_lb.egress.hostname
}

output "nlb_private_ips" {
  description = "All private IP objects assigned to the NLB. Use the first one as next hop."
  value       = ibm_is_lb.egress.private_ips
}

output "nlb_first_private_ip" {
  description = "First private IP address assigned to the NLB. This is the next-hop used in the VPC routing table."
  value       = local.nlb_next_hop_ip
}

output "routing_table_id" {
  description = "Custom VPC routing table ID for Transit Gateway ingress."
  value       = ibm_is_vpc_routing_table.egress_tgw.routing_table
}

output "transit_gateway_id" {
  description = "Transit Gateway ID."
  value       = ibm_tg_gateway.egress.id
}

output "transit_gateway_crn" {
  description = "Transit Gateway CRN."
  value       = ibm_tg_gateway.egress.crn
}

output "powervs_tg_connection_id" {
  description = "Transit Gateway connection ID for the PowerVS workspace."
  value       = ibm_tg_connection.powervs.id
}

output "vpc_tg_connection_id" {
  description = "Transit Gateway connection ID for the egress VPC."
  value       = ibm_tg_connection.vpc.id
}
