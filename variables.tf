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
  description = "Map of target regions where Terraform must create a full egress hub. Each entry creates one VPC, subnet, Public Gateway, NLB, routing table, local TGW, and VPC TGW connection for that region."
  type = map(object({
    region                           = string
    zone                             = string
    vpc_address_prefix_cidr          = string
    powervs_subnet_cidrs             = list(string)
    internet_ingress_allowed_ports   = optional(list(number), [])
    allow_ssh_and_ping_on_default_sg = optional(bool, true)
  }))

  validation {
    condition     = length(var.regional_hubs) > 0
    error_message = "Define at least one regional_hubs entry. Each entry represents one region where Terraform will create a VPC, NLB, routing, and a local Transit Gateway."
  }

  validation {
    condition = alltrue([
      for k, hub in var.regional_hubs : (
        length(trimspace(hub.region)) > 0 &&
        length(trimspace(hub.zone)) > 0 &&
        can(cidrhost(hub.vpc_address_prefix_cidr, 0)) &&
        length(hub.powervs_subnet_cidrs) > 0 &&
        alltrue([for cidr in hub.powervs_subnet_cidrs : can(cidrhost(cidr, 0))])
      )
    ])
    error_message = "Each regional_hubs entry must define a valid region, zone, VPC CIDR, and at least one valid PowerVS subnet CIDR."
  }
}

variable "powervs_workspaces" {
  description = "Map of PowerVS workspaces and the regional hub key they must attach to. region_key must match a key in regional_hubs."
  type = map(object({
    crn        = string
    region_key = string
  }))

  validation {
    condition = alltrue([
      for k, ws in var.powervs_workspaces : contains(keys(var.regional_hubs), ws.region_key)
    ])
    error_message = "Each powervs_workspaces entry must reference an existing key in regional_hubs through region_key."
  }
}
