variable "ibmcloud_api_key" {
  description = "IBM Cloud API key. Prefer exporting TF_VAR_ibmcloud_api_key instead of hardcoding it."
  type        = string
  sensitive   = true
}

variable "provider_region" {
  description = "Provider control-plane region. Use a region where you manage the stack from, for example eu-de or eu-es. This does not limit the regions defined in regional_hubs."
  type        = string
  default     = "eu-de"
}

variable "resource_group_name" {
  description = "Existing IBM Cloud resource group name where the infrastructure will be created."
  type        = string
}

variable "vpc_tags" {
  description = "Optional IBM Cloud tags to apply to supported resources."
  type        = list(string)
  default     = []
}

variable "regional_hubs" {
  description = "Map of regional egress hubs. One VPC, subnet, NLB, routing table, local TGW, and VPC-to-TGW connection will be created per entry."
  type = map(object({
    region                         = string
    zone                           = string
    vpc_address_prefix_cidr        = string
    powervs_subnet_cidrs           = list(string)
    internet_ingress_allowed_ports = optional(list(number), [])
    allow_ssh_and_ping_on_default_sg = optional(bool, true)
  }))
}

variable "powervs_workspaces" {
  description = "Map of PowerVS workspaces and the regional hub key they must attach to. region_key must match a key in regional_hubs."
  type = map(object({
    crn        = string
    region_key = string
  }))
}
