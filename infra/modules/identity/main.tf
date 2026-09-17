# ================================================================
# Entra ID Groups — least-privilege access model
# ================================================================
resource "azuread_group" "cloud_engineers" {
  display_name     = "cloud-engineers"
  security_enabled = true
  description      = "Cloud engineering team — Contributor on workload spokes"
}

resource "azuread_group" "security_auditors" {
  display_name     = "security-auditors"
  security_enabled = true
  description      = "Security audit team — read-only across subscription"
}

resource "azuread_group" "network_admins" {
  display_name     = "network-admins"
  security_enabled = true
  description      = "Network team — Network Contributor on Hub only"
}

# ================================================================
# Custom RBAC Role: VNet-Reader (least privilege)
# ================================================================
resource "azurerm_role_definition" "vnet_reader" {
  name        = "VNet-Reader"
  scope       = "/subscriptions/${var.subscription_id}"
  description = "Read-only access to VNets, subnets, NSGs and route tables"


  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/routeTables/read",
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription_id}"
  ]
}

# ================================================================
# Role Assignments — Scope-limited, least privilege
# ================================================================

# cloud-engineers → Contributor on Spoke-App RG
resource "azurerm_role_assignment" "cloud_engineers_spoke_app" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.spoke_app_resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = azuread_group.cloud_engineers.object_id
}

# cloud-engineers → Contributor on Spoke-Data RG
resource "azurerm_role_assignment" "cloud_engineers_spoke_data" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.spoke_data_resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = azuread_group.cloud_engineers.object_id
}

# network-admins → Network Contributor on Hub RG
resource "azurerm_role_assignment" "network_admins_hub" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.hub_resource_group_name}"
  role_definition_name = "Network Contributor"
  principal_id         = azuread_group.network_admins.object_id
}

# security-auditors → Reader on subscription (read-only)
resource "azurerm_role_assignment" "security_auditors_subscription" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azuread_group.security_auditors.object_id
}

# security-auditors → custom VNet-Reader on Hub (read VNet without full Reader)
resource "azurerm_role_assignment" "security_auditors_vnet_reader" {
  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${var.hub_resource_group_name}"
  role_definition_id = azurerm_role_definition.vnet_reader.role_definition_resource_id
  principal_id       = azuread_group.security_auditors.object_id
}