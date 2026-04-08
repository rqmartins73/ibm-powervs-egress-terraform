output "vpc_id" { value = ibm_is_vpc.egress.id }
output "vpc_crn" { value = ibm_is_vpc.egress.crn }
output "subnet_id" { value = ibm_is_subnet.egress.id }
output "public_gateway_id" { value = ibm_is_public_gateway.egress.id }
output "default_security_group_id" { value = ibm_is_vpc.egress.default_security_group }
output "nlb_id" { value = ibm_is_lb.egress.id }
output "nlb_hostname" { value = ibm_is_lb.egress.hostname }
output "nlb_private_ips" { value = ibm_is_lb.egress.private_ips }
output "nlb_first_private_ip" { value = one(ibm_is_lb.egress.private_ips) }
output "routing_table_id" { value = ibm_is_vpc_routing_table.egress_tgw.routing_table }
output "transit_gateway_id" { value = ibm_tg_gateway.regional.id }
output "transit_gateway_crn" { value = ibm_tg_gateway.regional.crn }
output "vpc_tg_connection_id" { value = ibm_tg_connection.vpc.id }
output "powervs_tg_connection_ids" {
  value = { for k, v in ibm_tg_connection.powervs : k => v.id }
}
