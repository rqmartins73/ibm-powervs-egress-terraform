variable "ibmcloud_api_key" {
  description = "IBM Cloud API key. Prefer exporting TF_VAR_ibmcloud_api_key instead of hardcoding it."
  type        = string
  sensitive   = true
}

variable "provider_region" {
  description = "Control-plane provider region for generic lookups. Regional infrastructure is created by aliased providers per supported region."
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
  description = "Map of regional hubs. Supported region keys in this version: eu-de and eu-es."
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
    error_message = "Define at least one regional_hubs entry."
  }

  validation {
    condition = alltrue([
      for k, hub in var.regional_hubs : (
        contains(["eu-de", "eu-es"], k) &&
        hub.region == k &&
        length(trimspace(hub.zone)) > 0 &&
        can(cidrhost(hub.vpc_address_prefix_cidr, 0)) &&
        length(hub.powervs_subnet_cidrs) > 0 &&
        alltrue([for cidr in hub.powervs_subnet_cidrs : can(cidrhost(cidr, 0))])
      )
    ])
    error_message = "This version supports only eu-de and eu-es regional_hubs, with region matching the map key and valid CIDRs."
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
