output "resource_group_id" {
  description = "Resolved resource group ID."
  value       = data.ibm_resource_group.rg.id
}

output "vpc_ids" {
  description = "Egress VPC IDs by regional hub key."
  value = {
    for k, v in ibm_is_vpc.egress : k => v.id
  }
}

output "vpc_crns" {
  description = "Egress VPC CRNs by regional hub key."
  value = {
    for k, v in ibm_is_vpc.egress : k => v.crn
  }
}

output "subnet_ids" {
  description = "Subnet IDs hosting the private NLBs by regional hub key."
  value = {
    for k, v in ibm_is_subnet.egress : k => v.id
  }
}

output "public_gateway_ids" {
  description = "Public gateway IDs by regional hub key."
  value = {
    for k, v in ibm_is_public_gateway.egress : k => v.id
  }
}

output "default_security_group_ids" {
  description = "Default VPC security group IDs by regional hub key."
  value = {
    for k, v in ibm_is_vpc.egress : k => v.default_security_group
  }
}

output "nlb_ids" {
  description = "Private NLB IDs by regional hub key."
  value = {
    for k, v in ibm_is_lb.egress : k => v.id
  }
}

output "nlb_hostnames" {
  description = "Private NLB hostnames by regional hub key."
  value = {
    for k, v in ibm_is_lb.egress : k => v.hostname
  }
}

output "nlb_private_ips" {
  description = "All private IP objects assigned to each NLB, by regional hub key."
  value = {
    for k, v in ibm_is_lb.egress : k => v.private_ips
  }
}

output "nlb_first_private_ips" {
  description = "First private IP address assigned to each NLB. These are the next hops used in the VPC routing tables."
  value       = local.nlb_next_hop_ips
}

output "routing_table_ids" {
  description = "Custom VPC routing table IDs by regional hub key."
  value = {
    for k, v in ibm_is_vpc_routing_table.egress_tgw : k => v.routing_table
  }
}

output "transit_gateway_ids" {
  description = "Local Transit Gateway IDs by regional hub key."
  value = {
    for k, v in ibm_tg_gateway.regional : k => v.id
  }
}

output "transit_gateway_crns" {
  description = "Local Transit Gateway CRNs by regional hub key."
  value = {
    for k, v in ibm_tg_gateway.regional : k => v.crn
  }
}

output "powervs_tg_connection_ids" {
  description = "Transit Gateway connection IDs for the PowerVS workspaces."
  value = {
    for k, v in ibm_tg_connection.powervs : k => v.id
  }
}

output "vpc_tg_connection_ids" {
  description = "Transit Gateway connection IDs for the egress VPCs by regional hub key."
  value = {
    for k, v in ibm_tg_connection.vpc : k => v.id
  }
}


output "regions_created" {
  description = "Regional hub keys where Terraform creates VPCs, NLBs, routing, and TGWs."
  value       = keys(var.regional_hubs)
}
