output "resource_group_name" {
  value = azurerm_resource_group.workload.name
}

output "vnet_id" {
  value = azurerm_virtual_network.workload.id
}

output "vnet_name" {
  value = azurerm_virtual_network.workload.name
}

output "subnet_id" {
  value = azurerm_subnet.workload_default.id
}

output "management_group_id" {
  value = var.management_group_id
}