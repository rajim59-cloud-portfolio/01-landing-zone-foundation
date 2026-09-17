# ─── Common ───────────────────────────────────────────────────────
variable "name" {
  description = "Spoke name (app, data, etc.) — used in resource naming"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags applied to all spoke resources"
  type        = map(string)
}

# ─── Networking ───────────────────────────────────────────────────
variable "vnet_cidr" {
  description = "Address space for spoke VNet"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    name           = string
    address_prefix = string
  }))
}

variable "remote_spoke_cidrs" {
  description = "List of remote spoke CIDRs to route explicitly via Firewall to override peering routes"
  type        = list(string)
  default     = []
}

# ─── Hub Reference ────────────────────────────────────────────────
variable "hub_vnet_id" {
  description = "Hub VNet resource ID (for peering)"
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name (for reverse peering)"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Hub resource group name (for reverse peering)"
  type        = string
}

variable "hub_vnet_cidr" {
  description = "Hub VNet CIDR (for NSG rules)"
  type        = string
}

variable "firewall_private_ip" {
  description = "Firewall private IP (for route table next hop)"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "Bastion subnet CIDR (for NSG allowing SSH)"
  type        = string
}