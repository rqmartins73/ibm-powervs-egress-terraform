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
  description = "IBM Cloud region for the VPC and Transit Gateway, for example eu-de, eu-gb, us-south."
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
  description = "Single VPC availability zone to use for this deployment, for example eu-de-1."
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

variable "transit_gateway_name" {
  description = "Name of the Transit Gateway."
  type        = string
  default     = "internet-tgw"
}

variable "transit_gateway_global" {
  description = "When true, creates the Transit Gateway with global routing so PowerVS workspaces in multiple regions can connect to it."
  type        = bool
  default     = true
}

variable "powervs_workspace_crns" {
  description = "List of CRNs of the existing PowerVS workspaces to connect to the Transit Gateway."
  type        = list(string)
}

variable "powervs_connection_name_prefix" {
  description = "Transit Gateway connection name prefix for the PowerVS workspaces."
  type        = string
  default     = "powervs-workspace-connection"
}

variable "vpc_connection_name" {
  description = "Transit Gateway connection name for the dedicated egress VPC."
  type        = string
  default     = "egress-vpc-connection"
}
