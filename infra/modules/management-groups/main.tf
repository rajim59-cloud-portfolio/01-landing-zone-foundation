# ================================================================
# Management Group Hierarchy (CAF-aligned)
#   Tenant Root
#   ├── Platform
#   │   ├── Identity
#   │   ├── Management
#   │   └── Connectivity
#   ├── Workloads
#   │   ├── Production
#   │   └── NonProduction
#   └── Sandbox
# ================================================================

# ─── Top-level MGs ───────────────────────────────────────────────
resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  parent_management_group_id = var.root_management_group_id
}

resource "azurerm_management_group" "workloads" {
  display_name               = "Workloads"
  parent_management_group_id = var.root_management_group_id
}

resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  parent_management_group_id = var.root_management_group_id
}

# ─── Platform children ───────────────────────────────────────────
resource "azurerm_management_group" "platform_identity" {
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "platform_management" {
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "platform_connectivity" {
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

# ─── Workloads children ──────────────────────────────────────────
resource "azurerm_management_group" "workloads_prod" {
  display_name               = "Production"
  parent_management_group_id = azurerm_management_group.workloads.id
}

resource "azurerm_management_group" "workloads_nonprod" {
  display_name               = "NonProduction"
  parent_management_group_id = azurerm_management_group.workloads.id
}

# ─── Subscription association (optional) ─────────────────────────
resource "azurerm_management_group_subscription_association" "platform" {
  for_each = toset(var.platform_subscription_ids)

  management_group_id = azurerm_management_group.platform_connectivity.id
  subscription_id     = "/subscriptions/${each.value}"
}

resource "azurerm_management_group_subscription_association" "workloads_prod" {
  for_each = toset(var.workloads_subscription_ids)

  management_group_id = azurerm_management_group.workloads_prod.id
  subscription_id     = "/subscriptions/${each.value}"
}

resource "azurerm_management_group_subscription_association" "sandbox" {
  for_each = toset(var.sandbox_subscription_ids)

  management_group_id = azurerm_management_group.sandbox.id
  subscription_id     = "/subscriptions/${each.value}"
}