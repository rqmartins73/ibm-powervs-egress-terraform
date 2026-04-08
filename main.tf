data "ibm_resource_group" "rg" {
  name = var.resource_group_name
}

locals {
  regional_hubs = {
    for key, hub in var.regional_hubs : key => {
      region                           = hub.region
      zone                             = hub.zone
      vpc_address_prefix_cidr          = hub.vpc_address_prefix_cidr
      powervs_subnet_cidrs             = hub.powervs_subnet_cidrs
      internet_ingress_allowed_ports   = try(hub.internet_ingress_allowed_ports, [])
      allow_ssh_and_ping_on_default_sg = try(hub.allow_ssh_and_ping_on_default_sg, true)
    }
  }

  eu_de_hubs = { for k, v in local.regional_hubs : k => v if k == "eu-de" }
  eu_es_hubs = { for k, v in local.regional_hubs : k => v if k == "eu-es" }

  powervs_eu_de = { for k, v in var.powervs_workspaces : k => v if v.region_key == "eu-de" }
  powervs_eu_es = { for k, v in var.powervs_workspaces : k => v if v.region_key == "eu-es" }
}

module "regional_hub_eu_de" {
  source    = "./modules/regional_hub"
  providers = { ibm = ibm.eu_de }
  for_each  = local.eu_de_hubs

  region_key         = each.key
  hub                = each.value
  resource_group_id  = data.ibm_resource_group.rg.id
  vpc_tags           = var.vpc_tags
  powervs_workspaces = local.powervs_eu_de
}

module "regional_hub_eu_es" {
  source    = "./modules/regional_hub"
  providers = { ibm = ibm.eu_es }
  for_each  = local.eu_es_hubs

  region_key         = each.key
  hub                = each.value
  resource_group_id  = data.ibm_resource_group.rg.id
  vpc_tags           = var.vpc_tags
  powervs_workspaces = local.powervs_eu_es
}
