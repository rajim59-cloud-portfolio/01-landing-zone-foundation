output "resource_group_name" {
  description = "Hub resource group name"
  value       = azurerm_resource_group.hub.name
}

output "hub_vnet_id" {
  description = "Hub VNet resource ID (used by spokes for peering)"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Hub VNet name (used by spokes for reverse peering)"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP (used in spoke route tables)"
  value       = cidrhost(var.firewall_subnet_cidr, 4)
}

output "bastion_subnet_cidr" {
  description = "Bastion subnet CIDR (used by spoke NSGs to allow SSH)"
  value       = var.bastion_subnet_cidr
}

output "firewall_id" {
  description = "Azure Firewall resource ID"
  value       = azurerm_firewall.hub.id
}

output "bastion_id" {
  description = "Azure Bastion resource ID"
  value       = azurerm_bastion_host.hub.id
}
