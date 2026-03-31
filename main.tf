data "ibm_resource_group" "rg" {
  name = var.resource_group_name
}

locals {
  default_sg_id = ibm_is_vpc.egress.default_security_group

  powervs_workspace_crn_map = {
    for idx, crn in var.powervs_workspace_crns :
    format("%02d", idx + 1) => crn
  }
}

resource "ibm_is_vpc" "egress" {
  name           = var.vpc_name
  resource_group = data.ibm_resource_group.rg.id
  tags           = var.vpc_tags

  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "egress" {
  name = var.vpc_address_prefix_name
  vpc  = ibm_is_vpc.egress.id
  zone = var.vpc_zone
  cidr = var.vpc_address_prefix_cidr
}

resource "ibm_is_public_gateway" "egress" {
  name           = "${var.subnet_name}-pgw"
  vpc            = ibm_is_vpc.egress.id
  zone           = var.vpc_zone
  resource_group = data.ibm_resource_group.rg.id
  tags           = var.vpc_tags
}

resource "ibm_is_subnet" "egress" {
  name                     = var.subnet_name
  vpc                      = ibm_is_vpc.egress.id
  zone                     = var.vpc_zone
  ipv4_cidr_block          = var.vpc_address_prefix_cidr
  public_gateway           = ibm_is_public_gateway.egress.id
  resource_group           = data.ibm_resource_group.rg.id
  total_ipv4_address_count = 16
  tags                     = var.vpc_tags

  depends_on = [ibm_is_vpc_address_prefix.egress]
}

resource "ibm_is_security_group_rule" "default_inbound_ssh" {
  count     = var.allow_ssh_and_ping_on_default_sg ? 1 : 0
  group     = local.default_sg_id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "default_inbound_ping" {
  count     = var.allow_ssh_and_ping_on_default_sg ? 1 : 0
  group     = local.default_sg_id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
    code = 0
  }
}

resource "ibm_is_security_group_rule" "nlb_from_powervs_all" {
  for_each  = toset(var.powervs_subnet_cidrs)
  group     = local.default_sg_id
  direction = "inbound"
  remote    = each.value
  protocol  = "all"
}

resource "ibm_is_security_group_rule" "nlb_from_internet_tcp" {
  for_each  = toset([for p in var.internet_ingress_allowed_ports : tostring(p)])
  group     = local.default_sg_id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = tonumber(each.key)
    port_max = tonumber(each.key)
  }
}

resource "ibm_is_lb" "egress" {
  name            = var.nlb_name
  subnets         = [ibm_is_subnet.egress.id]
  type            = "private"
  profile         = "network-fixed"
  route_mode      = true
  security_groups = [local.default_sg_id]
  resource_group  = data.ibm_resource_group.rg.id
  tags            = var.vpc_tags
}

resource "ibm_is_lb_pool" "egress" {
  lb             = ibm_is_lb.egress.id
  name           = var.nlb_pool_name
  algorithm      = "round_robin"
  protocol       = "tcp"
  health_delay   = 5
  health_retries = 2
  health_timeout = 2
  health_type    = "tcp"
  proxy_protocol = "disabled"

  failsafe_policy {
    action = "bypass"
  }
}

resource "ibm_is_lb_listener" "egress" {
  lb           = ibm_is_lb.egress.id
  port         = 1
  protocol     = "tcp"
  default_pool = ibm_is_lb_pool.egress.id
}

locals {
  nlb_private_ip_objects = try(ibm_is_lb.egress.private_ips, [])
  nlb_next_hop_ip        = try(local.nlb_private_ip_objects[0].address, null)
}

resource "ibm_is_vpc_routing_table" "egress_tgw" {
  vpc                           = ibm_is_vpc.egress.id
  name                          = var.routing_table_name
  route_transit_gateway_ingress = true
  advertise_routes_to           = ["transit_gateway"]
}

resource "ibm_is_vpc_routing_table_route" "default_to_nlb" {
  vpc           = ibm_is_vpc.egress.id
  routing_table = ibm_is_vpc_routing_table.egress_tgw.routing_table
  zone          = var.vpc_zone
  name          = var.routing_table_route_name
  destination   = "0.0.0.0/0"
  action        = "deliver"
  next_hop      = local.nlb_next_hop_ip
  advertise     = true

  depends_on = [ibm_is_lb_listener.egress]
}

resource "ibm_tg_gateway" "egress" {
  name           = var.transit_gateway_name
  location       = var.region
  global         = false
  resource_group = data.ibm_resource_group.rg.id
  tags           = var.vpc_tags
}

resource "ibm_tg_connection" "powervs" {
  for_each = local.powervs_workspace_crn_map

  gateway      = ibm_tg_gateway.egress.id
  name         = "${var.powervs_connection_name_prefix}-${each.key}"
  network_type = "power_virtual_server"
  network_id   = each.value
}

resource "ibm_tg_connection" "vpc" {
  gateway      = ibm_tg_gateway.egress.id
  name         = var.vpc_connection_name
  network_type = "vpc"
  network_id   = ibm_is_vpc.egress.crn
}
