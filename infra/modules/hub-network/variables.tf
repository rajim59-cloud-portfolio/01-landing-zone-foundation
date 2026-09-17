# ─── Common ───────────────────────────────────────────────────────
variable "location" {
  description = "Azure region for hub resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to all hub resources"
  type        = map(string)
}

# ─── CIDR Plan ────────────────────────────────────────────────────
variable "hub_vnet_cidr" {
  description = "Address space for Hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_subnet_cidr" {
  description = "AzureFirewallSubnet CIDR (must be /26 or larger)"
  type        = string
  default     = "10.0.1.0/26"
}

variable "bastion_subnet_cidr" {
  description = "AzureBastionSubnet CIDR (must be /26 or larger)"
  type        = string
  default     = "10.0.2.0/26"
}

variable "gateway_subnet_cidr" {
  description = "GatewaySubnet CIDR (reserved for future VPN/ER)"
  type        = string
  default     = "10.0.3.0/27"
}

variable "shared_services_subnet_cidr" {
  description = "SharedServicesSubnet CIDR"
  type        = string
  default     = "10.0.4.0/24"
}

variable "firewall_mgmt_subnet_cidr" {
  description = "AzureFirewallManagementSubnet CIDR (required for Basic SKU, must be /26 or larger)"
  type        = string
  default     = "10.0.5.0/26"
}