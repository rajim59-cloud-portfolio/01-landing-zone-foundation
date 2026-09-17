output "cloud_engineers_group_id" {
  value = azuread_group.cloud_engineers.object_id
}

output "security_auditors_group_id" {
  value = azuread_group.security_auditors.object_id
}

output "network_admins_group_id" {
  value = azuread_group.network_admins.object_id
}

output "vnet_reader_role_id" {
  value = azurerm_role_definition.vnet_reader.role_definition_resource_id
}
