data "azurerm_client_config" "current" {}

# ================================================================
# Resource Group for monitoring
# ================================================================
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring"
  location = var.location
  tags     = var.tags
}

# ================================================================
# Log Analytics Workspace (centralised logging)
# ================================================================
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-landing-zone"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  daily_quota_gb      = var.daily_quota_gb
  tags                = var.tags
}

# ================================================================
# Diagnostic Settings — send logs to LAW
# ================================================================
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-firewall"
  target_resource_id         = var.firewall_resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }
  enabled_log {
    category = "AzureFirewallApplicationRule"
  }
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
  name                       = "diag-bastion"
  target_resource_id         = var.bastion_resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "BastionAuditLogs"
  }
}

resource "azurerm_monitor_diagnostic_setting" "spoke_app_vnet" {
  name                       = "diag-spoke-app-vnet"
  target_resource_id         = var.spoke_app_vnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "spoke_data_vnet" {
  name                       = "diag-spoke-data-vnet"
  target_resource_id         = var.spoke_data_vnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
  }
}

# ================================================================
# Action Group (email alerts)
# ================================================================
resource "azurerm_monitor_action_group" "email" {
  name                = "ag-email-alerts"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "emailalerts"

  email_receiver {
    name          = "SendToAdmin"
    email_address = var.alert_email
  }
}

# ================================================================
# Budget + Alerts (50/80/100%)
# ================================================================
resource "azurerm_consumption_budget_subscription" "budget" {
  name            = "budget-landing-zone"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  amount          = var.budget_amount_usd
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 50.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }
}

# ================================================================
# Alert Rule: Firewall Denied Traffic > 100 in 15 min
# ================================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "firewall_denied" {
  name                = "alert-firewall-denied-traffic"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  description         = "Firewall denied more than 100 packets in 15 minutes"
  severity            = 2
  enabled             = true
  tags                = var.tags

  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"
  scopes               = [azurerm_log_analytics_workspace.law.id]

  criteria {
    query                   = file("${path.module}/queries/denied-traffic.kql")
    time_aggregation_method = "Count"
    threshold               = 100
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.email.id]
  }
}