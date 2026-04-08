variable "region_key" { type = string }

variable "hub" {
  type = object({
    region                           = string
    zone                             = string
    vpc_address_prefix_cidr          = string
    powervs_subnet_cidrs             = list(string)
    internet_ingress_allowed_ports   = list(number)
    allow_ssh_and_ping_on_default_sg = bool
  })
}

variable "resource_group_id" { type = string }

variable "vpc_tags" {
  type    = list(string)
  default = []
}

variable "powervs_workspaces" {
  type = map(object({
    crn        = string
    region_key = string
  }))
}
