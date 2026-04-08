locals {
  regional_modules = merge(
    { for k, m in module.regional_hub_eu_de : k => m },
    { for k, m in module.regional_hub_eu_es : k => m }
  )
}

output "resource_group_id" {
  description = "Resolved resource group ID."
  value       = data.ibm_resource_group.rg.id
}

output "vpc_ids" { value = { for k, m in local.regional_modules : k => m.vpc_id } }
output "vpc_crns" { value = { for k, m in local.regional_modules : k => m.vpc_crn } }
output "subnet_ids" { value = { for k, m in local.regional_modules : k => m.subnet_id } }
output "public_gateway_ids" { value = { for k, m in local.regional_modules : k => m.public_gateway_id } }
output "default_security_group_ids" { value = { for k, m in local.regional_modules : k => m.default_security_group_id } }
output "nlb_ids" { value = { for k, m in local.regional_modules : k => m.nlb_id } }
output "nlb_hostnames" { value = { for k, m in local.regional_modules : k => m.nlb_hostname } }
output "nlb_private_ips" { value = { for k, m in local.regional_modules : k => m.nlb_private_ips } }
output "nlb_first_private_ips" { value = { for k, m in local.regional_modules : k => m.nlb_first_private_ip } }
output "routing_table_ids" { value = { for k, m in local.regional_modules : k => m.routing_table_id } }
output "transit_gateway_ids" { value = { for k, m in local.regional_modules : k => m.transit_gateway_id } }
output "transit_gateway_crns" { value = { for k, m in local.regional_modules : k => m.transit_gateway_crn } }
output "powervs_tg_connection_ids" {
  value = merge(
    try(module.regional_hub_eu_de["eu-de"].powervs_tg_connection_ids, {}),
    try(module.regional_hub_eu_es["eu-es"].powervs_tg_connection_ids, {})
  )
}
output "vpc_tg_connection_ids" { value = { for k, m in local.regional_modules : k => m.vpc_tg_connection_id } }
output "regions_created" { value = keys(var.regional_hubs) }
