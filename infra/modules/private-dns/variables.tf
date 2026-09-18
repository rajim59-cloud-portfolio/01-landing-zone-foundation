variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "hub_resource_group_name" {
  type = string
}

variable "hub_vnet_id" {
  type = string
}

variable "spoke_vnet_ids" {
  description = "Map of spoke name → VNet ID (for DNS zone VNet links)"
  type        = map(string)
}

variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type        = list(string)
  default = [
    "privatelink.postgres.database.azure.com",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurewebsites.net",
  ]
}