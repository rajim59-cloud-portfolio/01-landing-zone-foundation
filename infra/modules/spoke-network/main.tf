# ================================================================
# Resource Group
# ================================================================
resource "azurerm_resource_group" "spoke" {
  name     = "rg-spoke-${var.name}"
  location = var.location
  tags     = var.tags
}

# ================================================================
# Spoke Virtual Network
# ================================================================
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.name}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# ─── Subnets (for_each so new subnets are easy to add) ───────────
resource "azurerm_subnet" "spoke" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [each.value.address_prefix]

  # App Service VNet Integration Delegation (Only on "app" subnet)
  dynamic "delegation" {
    for_each = each.key == "app" ? [1] : []
    content {
      name = "delegation-appservice"
      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

# ================================================================
# Network Security Group
# ================================================================
resource "azurerm_network_security_group" "spoke" {
  name                = "nsg-spoke-${var.name}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags

  # Allow all traffic from Hub (Bastion, Firewall, monitoring)
  security_rule {
    name                       = "AllowHubInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.hub_vnet_cidr
    destination_address_prefix = "*"
  }

  # Allow SSH from Bastion subnet specifically
  security_rule {
    name                       = "AllowBastionSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_subnet_cidr
    destination_address_prefix = "*"
  }

  # Deny all other inbound from Internet
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Associate NSG with each subnet
resource "azurerm_subnet_network_security_group_association" "spoke" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.spoke[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke.id
}

# ================================================================
# Route Table — send outbound and inter-spoke traffic through Firewall
# ================================================================
resource "azurerm_route_table" "spoke" {
  name                          = "rt-spoke-${var.name}"
  location                      = azurerm_resource_group.spoke.location
  resource_group_name           = azurerm_resource_group.spoke.name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  # Default Route for Internet and unmatched traffic
  route {
    name                   = "to-firewall-default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }

  # Explicit UDRs for remote spokes to prevent Peering bypass (LPM Fix)
  dynamic "route" {
    for_each = var.remote_spoke_cidrs
    content {
      name                   = "to-firewall-spoke-${replace(route.value, "/", "-")}"
      address_prefix         = route.value
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    }
  }
}

# Associate route table with each subnet
resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = var.subnets

  subnet_id      = azurerm_subnet.spoke[each.key].id
  route_table_id = azurerm_route_table.spoke.id
}

# ================================================================
# VNet Peering (bidirectional)
# ================================================================
# Spoke → Hub (peering resource lives in spoke RG)
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${var.name}-to-hub"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Hub → Spoke (peering resource lives in hub RG)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${var.name}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}