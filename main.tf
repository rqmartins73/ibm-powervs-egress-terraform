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
      vpc_name                         = "powervs-internet-vpc-${key}"
      vpc_address_prefix_name          = "nlb-prefix-${key}"
      subnet_name                      = "powervs-internet-subnet-${key}"
      nlb_name                         = "powervs-egress-nlb-${key}"
      nlb_pool_name                    = "powervs-egress-pool-${key}"
      routing_table_name               = "tgw-nlb-default-route-${key}"
      routing_table_route_name         = "default-route-${key}"
      transit_gateway_name             = "internet-tgw-${key}"
      vpc_connection_name              = "egress-vpc-connection-${key}"
      powervs_connection_name_prefix   = "powervs-workspace-connection-${key}"
    }
  }

  ssh_ping_regions = {
    for key, hub in local.regional_hubs : key => hub
    if hub.allow_ssh_and_ping_on_default_sg
  }

  powervs_sg_rules = merge([
    for region_key, hub in local.regional_hubs : {
      for cidr in hub.powervs_subnet_cidrs : "${region_key}|${cidr}" => {
        region_key = region_key
        cidr       = cidr
      }
    }
  ]...)

  internet_tcp_rules = merge([
    for region_key, hub in local.regional_hubs : {
      for port in hub.internet_ingress_allowed_ports : "${region_key}|${port}" => {
        region_key = region_key
        port       = port
      }
    }
  ]...)

  workspaces_by_region = {
    for key, ws in var.powervs_workspaces : key => ws
  }
}

resource "ibm_is_vpc" "egress" {
  for_each       = local.regional_hubs
  name           = each.value.vpc_name
  resource_group = data.ibm_resource_group.rg.id
  tags           = var.vpc_tags

  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "egress" {
  for_each = local.regional_hubs
  name     = each.value.vpc_address_prefix_name
  vpc      = ibm_is_vpc.egress[each.key].id
  zone     = each.value.zone
  cidr     = each.value.vpc_address_prefix_cidr
}

resource "ibm_is_public_gateway" "egress" {
  for_each       = local.regional_hubs
  name           = "${each.value.subnet_name}-pgw"
  vpc            = ibm_is_vpc.egress[each.key].id
  zone           = each.value.zone
  resource_group = data.ibm_resource_group.rg.id
  tags           = var.vpc_tags
}

resource "ibm_is_subnet" "egress" {
  for_each        = local.regional_hubs
  name            = each.value.subnet_name
  vpc             = ibm_is_vpc.egress[each.key].id
  zone            = each.value.zone
  ipv4_cidr_block = each.value.vpc_address_prefix_cidr
  public_gateway  = ibm_is_public_gateway.egress[each.key].id
  resource_group  = data.ibm_resource_group.rg.id
  tags            = var.vpc_tags

  depends_on = [ibm_is_vpc_address_prefix.egress]
}

resource "ibm_is_security_group_rule" "default_inbound_ssh" {
  for_each   = local.ssh_ping_regions
  group      = ibm_is_vpc.egress[each.key].default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"
  protocol   = "tcp"
  port_min   = 22
  port_max   = 22
  ip_version = "ipv4"
}

resource "ibm_is_security_group_rule" "default_inbound_ping" {
  for_each   = local.ssh_ping_regions
  group      = ibm_is_vpc.egress[each.key].default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"
  protocol   = "icmp"
  type       = 8
  code       = 0
  ip_version = "ipv4"
}

resource "ibm_is_security_group_rule" "nlb_from_powervs_all" {
  for_each   = local.powervs_sg_rules
  group      = ibm_is_vpc.egress[each.value.region_key].default_security_group
  direction  = "inbound"
  remote     = each.value.cidr
  protocol   = "icmp_tcp_udp"
  ip_version = "ipv4"
}

resource "ibm_is_security_group_rule" "nlb_from_internet_tcp" {
  for_each   = local.internet_tcp_rules
  group      = ibm_is_vpc.egress[each.value.region_key].default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"
  protocol   = "tcp"
  port_min   = each.value.port
  port_max   = each.value.port
  ip_version = "ipv4"
}

resource "ibm_is_lb" "egress" {
  for_each        = local.regional_hubs
  name            = each.value.nlb_name
  subnets         = [ibm_is_subnet.egress[each.key].id]
  type            = "private"
  profile         = "network-fixed"
  route_mode      = true
  security_groups = [ibm_is_vpc.egress[each.key].default_security_group]
  resource_group  = data.ibm_resource_group.rg.id
  tags            = var.vpc_tags
}

resource "ibm_is_lb_pool" "egress" {
  for_each       = local.regional_hubs
  lb             = ibm_is_lb.egress[each.key].id
  name           = each.value.nlb_pool_name
  algorithm      = "round_robin"
  protocol       = "tcp"
  health_delay   = 5
  health_retries = 2
  health_timeout = 2
  health_type    = "tcp"

  failsafe_policy {
    action = "bypass"
  }
}

resource "ibm_is_lb_listener" "egress" {
  for_each     = local.regional_hubs
  lb           = ibm_is_lb.egress[each.key].id
  port         = 1
  protocol     = "tcp"
  default_pool = ibm_is_lb_pool.egress[each.key].id
}

locals {
  nlb_next_hop_ips = {
    for region_key, lb in ibm_is_lb.egress :
    region_key => try(lb.private_ips[0].address, null)
  }
}

resource "ibm_is_vpc_routing_table" "egress_tgw" {
  for_each                       = local.regional_hubs
  vpc                            = ibm_is_vpc.egress[each.key].id
  name                           = each.value.routing_table_name
  route_transit_gateway_ingress  = true
  advertise_routes_to            = ["transit_gateway"]
}

resource "ibm_is_vpc_routing_table_route" "default_to_nlb" {
  for_each      = local.regional_hubs
  vpc           = ibm_is_vpc.egress[each.key].id
  routing_table = ibm_is_vpc_routing_table.egress_tgw[each.key].routing_table
  zone          = each.value.zone
  name          = each.value.routing_table_route_name
  destination   = "0.0.0.0/0"
  action        = "deliver"
  next_hop      = local.nlb_next_hop_ips[each.key]
  advertise     = true

  depends_on = [ibm_is_lb_listener.egress]
}

resource "ibm_tg_gateway" "regional" {
  for_each       = local.regional_hubs
  name           = each.value.transit_gateway_name
  location       = each.value.region
  global         = false
  resource_group = data.ibm_resource_group.rg.id
  tags           = var.vpc_tags
}

resource "ibm_tg_connection" "vpc" {
  for_each     = local.regional_hubs
  gateway      = ibm_tg_gateway.regional[each.key].id
  name         = each.value.vpc_connection_name
  network_type = "vpc"
  network_id   = ibm_is_vpc.egress[each.key].crn
}

resource "ibm_tg_connection" "powervs" {
  for_each     = local.workspaces_by_region
  gateway      = ibm_tg_gateway.regional[each.value.region_key].id
  name         = "${local.regional_hubs[each.value.region_key].powervs_connection_name_prefix}-${each.key}"
  network_type = "power_virtual_server"
  network_id   = each.value.crn
}
