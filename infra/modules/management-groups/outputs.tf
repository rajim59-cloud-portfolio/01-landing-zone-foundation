output "platform_mg_id" {
  value = azurerm_management_group.platform.id
}

output "workloads_mg_id" {
  value = azurerm_management_group.workloads.id
}

output "workloads_prod_mg_id" {
  value = azurerm_management_group.workloads_prod.id
}

output "workloads_nonprod_mg_id" {
  value = azurerm_management_group.workloads_nonprod.id
}

output "sandbox_mg_id" {
  value = azurerm_management_group.sandbox.id
}

output "platform_connectivity_mg_id" {
  value = azurerm_management_group.platform_connectivity.id
}