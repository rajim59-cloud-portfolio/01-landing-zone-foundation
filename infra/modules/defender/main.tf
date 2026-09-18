# ================================================================
# Defender for Cloud — Foundational CSPM (Free tier)
# ================================================================
resource "azurerm_security_center_subscription_pricing" "cspm_free" {
  # Free tier: Foundational CSPM (no cost)
  tier          = "Free"
  resource_type = "CloudPosture"
}

# ─── Optional: Defender for Servers (paid — off by default) ──────
resource "azurerm_security_center_subscription_pricing" "servers" {
  count = var.enable_servers_pricing ? 1 : 0

  tier          = "Standard"
  resource_type = "VirtualMachines"
  subplan       = "P1"
}

# ─── Optional: Defender CSPM (paid) ──────────────────────────────
resource "azurerm_security_center_subscription_pricing" "cspm_paid" {
  count = var.enable_cspm ? 1 : 0

  tier          = "Standard"
  resource_type = "CloudPosture"
  subplan       = "DefenderCSPMSecurityOperator"
}

# ================================================================
# Security Contact (for alerts)
# ================================================================
resource "azurerm_security_center_contact" "main" {
  name                = "default-contact"
  email               = var.alert_email
  phone               = "+1-555-555-5555"
  alert_notifications = true
  alerts_to_admins    = true
}

variable "alert_email" {
  type = string
}