# ================================================================
# Simulated Subscription Vending Module
# Models AVM pattern within subscription boundary
# ================================================================

resource "azurerm_resource_group" "workload" {
  name     = "rg-workload-${var.workload_name}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "workload" {
  name                = "vnet-workload-${var.workload_name}"
  location            = azurerm_resource_group.workload.location
  resource_group_name = azurerm_resource_group.workload.name
  address_space       = [var.workload_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "workload_default" {
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.workload.name
  virtual_network_name = azurerm_virtual_network.workload.name
  address_prefixes     = [cidrsubnet(var.workload_vnet_cidr, 8, 1)]
}

resource "azurerm_virtual_network_peering" "workload_to_hub" {
  name                      = "peer-${var.workload_name}-to-hub"
  resource_group_name       = azurerm_resource_group.workload.name
  virtual_network_name      = azurerm_virtual_network.workload.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_workload" {
  name                      = "peer-hub-to-${var.workload_name}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.workload.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_route_table" "workload" {
  name                          = "rt-workload-${var.workload_name}"
  location                      = azurerm_resource_group.workload.location
  resource_group_name           = azurerm_resource_group.workload.name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "workload" {
  subnet_id      = azurerm_subnet.workload_default.id
  route_table_id = azurerm_route_table.workload.id
}

resource "azurerm_consumption_budget_resource_group" "workload" {
  count = var.create_budget ? 1 : 0

  name              = "budget-${var.workload_name}"
  resource_group_id = azurerm_resource_group.workload.id
  amount            = var.budget_amount_usd
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }
}