locals {
  vpc_name                       = "powervs-internet-vpc-${var.region_key}"
  vpc_address_prefix_name        = "nlb-prefix-${var.region_key}"
  subnet_name                    = "powervs-internet-subnet-${var.region_key}"
  nlb_name                       = "powervs-egress-nlb-${var.region_key}"
  nlb_pool_name                  = "powervs-egress-pool-${var.region_key}"
  routing_table_name             = "tgw-nlb-default-route-${var.region_key}"
  routing_table_route_name       = "default-route-${var.region_key}"
  transit_gateway_name           = "internet-tgw-${var.region_key}"
  vpc_connection_name            = "egress-vpc-connection-${var.region_key}"
  powervs_connection_name_prefix = "powervs-workspace-connection-${var.region_key}"

  powervs_sg_rules = { for cidr in var.hub.powervs_subnet_cidrs : cidr => cidr }
  internet_tcp_rules = { for port in var.hub.internet_ingress_allowed_ports : tostring(port) => port }
}

resource "ibm_is_vpc" "egress" {
  name           = local.vpc_name
  resource_group = var.resource_group_id
  tags           = var.vpc_tags
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "egress" {
  name = local.vpc_address_prefix_name
  vpc  = ibm_is_vpc.egress.id
  zone = var.hub.zone
  cidr = var.hub.vpc_address_prefix_cidr
}

resource "ibm_is_public_gateway" "egress" {
  name           = "${local.subnet_name}-pgw"
  vpc            = ibm_is_vpc.egress.id
  zone           = var.hub.zone
  resource_group = var.resource_group_id
  tags           = var.vpc_tags
}

resource "ibm_is_subnet" "egress" {
  name            = local.subnet_name
  vpc             = ibm_is_vpc.egress.id
  zone            = var.hub.zone
  ipv4_cidr_block = var.hub.vpc_address_prefix_cidr
  public_gateway  = ibm_is_public_gateway.egress.id
  resource_group  = var.resource_group_id
  tags            = var.vpc_tags
  depends_on      = [ibm_is_vpc_address_prefix.egress]
}

resource "ibm_is_security_group_rule" "default_inbound_ssh" {
  count      = var.hub.allow_ssh_and_ping_on_default_sg ? 1 : 0
  group      = ibm_is_vpc.egress.default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"
  protocol   = "tcp"
  port_min   = 22
  port_max   = 22
  ip_version = "ipv4"
}

resource "ibm_is_security_group_rule" "default_inbound_ping" {
  count      = var.hub.allow_ssh_and_ping_on_default_sg ? 1 : 0
  group      = ibm_is_vpc.egress.default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"
  protocol   = "icmp"
  type       = 8
  code       = 0
  ip_version = "ipv4"
}

resource "ibm_is_security_group_rule" "nlb_from_powervs_all" {
  for_each   = local.powervs_sg_rules
  group      = ibm_is_vpc.egress.default_security_group
  direction  = "inbound"
  remote     = each.value
  protocol   = "icmp_tcp_udp"
  ip_version = "ipv4"
}

resource "ibm_is_security_group_rule" "nlb_from_internet_tcp" {
  for_each   = local.internet_tcp_rules
  group      = ibm_is_vpc.egress.default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"
  protocol   = "tcp"
  port_min   = each.value
  port_max   = each.value
  ip_version = "ipv4"
}

resource "ibm_is_lb" "egress" {
  name            = local.nlb_name
  subnets         = [ibm_is_subnet.egress.id]
  type            = "private"
  profile         = "network-fixed"
  route_mode      = true
  security_groups = [ibm_is_vpc.egress.default_security_group]
  resource_group  = var.resource_group_id
  tags            = var.vpc_tags
}

resource "ibm_is_lb_pool" "egress" {
  lb             = ibm_is_lb.egress.id
  name           = local.nlb_pool_name
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
  lb           = ibm_is_lb.egress.id
  port         = 1
  protocol     = "tcp"
  default_pool = ibm_is_lb_pool.egress.id
}

resource "ibm_is_vpc_routing_table" "egress_tgw" {
  vpc                           = ibm_is_vpc.egress.id
  name                          = local.routing_table_name
  route_transit_gateway_ingress = true
  advertise_routes_to           = ["transit_gateway"]
}

resource "ibm_is_vpc_routing_table_route" "default_to_nlb" {
  vpc           = ibm_is_vpc.egress.id
  routing_table = ibm_is_vpc_routing_table.egress_tgw.routing_table
  zone          = var.hub.zone
  name          = local.routing_table_route_name
  destination   = "0.0.0.0/0"
  action        = "deliver"
  next_hop      = ibm_is_lb.egress.private_ip
  advertise     = true
  depends_on    = [ibm_is_lb_listener.egress]
}

resource "ibm_tg_gateway" "regional" {
  name           = local.transit_gateway_name
  location       = var.hub.region
  global         = false
  resource_group = var.resource_group_id
  tags           = var.vpc_tags
}

resource "ibm_tg_connection" "vpc" {
  gateway      = ibm_tg_gateway.regional.id
  name         = local.vpc_connection_name
  network_type = "vpc"
  network_id   = ibm_is_vpc.egress.crn
}

resource "ibm_tg_connection" "powervs" {
  for_each     = var.powervs_workspaces
  gateway      = ibm_tg_gateway.regional.id
  name         = "${local.powervs_connection_name_prefix}-${each.key}"
  network_type = "power_virtual_server"
  network_id   = each.value.crn
}
