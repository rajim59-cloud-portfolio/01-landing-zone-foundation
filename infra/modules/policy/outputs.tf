output "require_tags_policy_id" {
  description = "ID of the require-tags policy definition"
  value       = azurerm_policy_definition.require_tags.id
}

output "allowed_locations_policy_id" {
  description = "ID of the allowed-locations policy definition"
  value       = azurerm_policy_definition.allowed_locations.id
}

output "deny_public_ip_policy_id" {
  description = "ID of the deny-public-ip policy definition"
  value       = azurerm_policy_definition.deny_public_ip.id
}

output "policy_assignment_ids" {
  description = "Map of policy assignment IDs"
  value = {
    require_tags      = azurerm_subscription_policy_assignment.require_tags.id
    allowed_locations = azurerm_subscription_policy_assignment.allowed_locations.id
    deny_public_ip    = azurerm_subscription_policy_assignment.deny_public_ip.id
  }
}
