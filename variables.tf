variable "ibmcloud_api_key" {
  description = "IBM Cloud API key. Prefer exporting TF_VAR_ibmcloud_api_key instead of hardcoding it."
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Existing IBM Cloud resource group name where the infrastructure will be created."
  type        = string
}

variable "region" {
  description = "IBM Cloud region where the dedicated egress VPC will be created, for example eu-es or eu-de."
  type        = string
}

variable "vpc_name" {
  description = "Name of the dedicated egress VPC."
  type        = string
  default     = "powervs-internet-vpc"
}

variable "vpc_tags" {
  description = "Optional IBM Cloud tags to apply to supported resources."
  type        = list(string)
  default     = []
}

variable "vpc_address_prefix_name" {
  description = "Name of the manually created address prefix."
  type        = string
  default     = "nlb-prefix"
}

variable "vpc_zone" {
  description = "Single VPC availability zone to use for this deployment, for example eu-es-2."
  type        = string
}

variable "vpc_address_prefix_cidr" {
  description = "CIDR for the address prefix and subnet that will host the NLB. Must not overlap with PowerVS, other VPCs, or on-prem networks. Minimum recommended size is /28."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet for the NLB."
  type        = string
  default     = "powervs-internet-subnet"
}

variable "allow_ssh_and_ping_on_default_sg" {
  description = "When true, adds basic inbound SSH and ICMP rules to the VPC default security group for troubleshooting."
  type        = bool
  default     = true
}

variable "powervs_subnet_cidrs" {
  description = "List of PowerVS subnet CIDRs that must be allowed to reach the NLB."
  type        = list(string)
}

variable "internet_ingress_allowed_ports" {
  description = "Internet-facing inbound TCP ports to allow on the NLB security group. Leave empty if you only want outbound internet access for now."
  type        = list(number)
  default     = []
}

variable "nlb_name" {
  description = "Name of the private network load balancer."
  type        = string
  default     = "powervs-egress-nlb"
}

variable "nlb_pool_name" {
  description = "Name of the NLB back-end pool."
  type        = string
  default     = "powervs-egress-pool"
}

variable "nlb_listener_name" {
  description = "Name label for the listener. The provider resource itself keys on the load balancer and port/protocol."
  type        = string
  default     = "powervs-egress-listener"
}

variable "routing_table_name" {
  description = "Name of the custom VPC routing table that accepts Transit Gateway ingress and advertises routes back."
  type        = string
  default     = "tgw-nlb-default-route"
}

variable "routing_table_route_name" {
  description = "Name of the default route in the custom routing table."
  type        = string
  default     = "default-route"
}

variable "transit_gateways" {
  description = "Map of local Transit Gateways to create. Set connect_vpc=true only for the TGW in the same region as the egress VPC."
  type = map(object({
    name        = string
    region      = string
    global      = optional(bool, false)
    connect_vpc = optional(bool, false)
  }))
}

variable "powervs_workspaces" {
  description = "Map of PowerVS workspaces and the Transit Gateway key each workspace must attach to."
  type = map(object({
    crn             = string
    tgw_key         = string
    connection_name = optional(string)
  }))
}

variable "powervs_connection_name_prefix" {
  description = "Transit Gateway connection name prefix for PowerVS workspaces when a per-workspace connection_name is not specified."
  type        = string
  default     = "powervs-workspace-connection"
}

variable "vpc_connection_name" {
  description = "Transit Gateway connection name for the dedicated egress VPC."
  type        = string
  default     = "egress-vpc-connection"
}
