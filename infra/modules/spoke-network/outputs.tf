output "resource_group_name" {
  description = "Spoke resource group name"
  value       = azurerm_resource_group.spoke.name
}

output "vnet_id" {
  description = "Spoke VNet resource ID"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Spoke VNet name"
  value       = azurerm_virtual_network.spoke.name
}

output "subnet_ids" {
  description = "Map of subnet name → subnet ID"
  value = {
    for key, subnet in azurerm_subnet.spoke : key => subnet.id
  }
}