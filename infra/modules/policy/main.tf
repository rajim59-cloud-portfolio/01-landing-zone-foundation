# ================================================================
# Policy Definition: Require Tags
# ================================================================
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-required-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require CostCenter, Env, and Owner tags"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field     = "type"
          notEquals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          anyOf = [
            { field = "tags['CostCenter']", exists = "false" },
            { field = "tags['Env']", exists = "false" },
            { field = "tags['Owner']", exists = "false" }
          ]
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })
}

# ================================================================
# Policy Definition: Allowed Locations
# ================================================================
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Restrict resources to approved regions"

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('allowedLocations')]"
      }
    }
    then = {
      effect = "deny"
    }
  })

  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed locations"
        description = "The list of locations where resources can be deployed"
      }
    }
  })

  metadata = jsonencode({
    category = "General"
    version  = "1.0.0"
  })
}

# ================================================================
# Policy Definition: Deny Public IP
# ================================================================
resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Deny public IP addresses except for shared services"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Network/publicIPAddresses"
        },
        {
          field     = "tags['Env']"
          notEquals = "shared"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })

  metadata = jsonencode({
    category = "Network"
    version  = "1.0.0"
  })
}

# ================================================================
# Policy Assignments
# ================================================================
resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "assign-require-tags"
  subscription_id      = var.scope_id
  policy_definition_id = azurerm_policy_definition.require_tags.id
  display_name         = "Require tags on all resources"
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "assign-allowed-locations"
  subscription_id      = var.scope_id
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  display_name         = "Allowed locations"

  parameters = jsonencode({
    allowedLocations = {
      value = var.allowed_locations
    }
  })
}

resource "azurerm_subscription_policy_assignment" "deny_public_ip" {
  name                 = "assign-deny-public-ip"
  subscription_id      = var.scope_id
  policy_definition_id = azurerm_policy_definition.deny_public_ip.id
  display_name         = "Deny public IPs unless Env=shared"
}