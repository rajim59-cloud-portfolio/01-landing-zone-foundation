# ================================================================
# Private DNS Zones (in Hub RG)
# ================================================================
resource "azurerm_private_dns_zone" "this" {
  for_each = toset(var.private_dns_zones)

  name                = each.value
  resource_group_name = var.hub_resource_group_name
  tags                = var.tags
}

# ─── Link zones to Hub VNet ──────────────────────────────────────
resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each = azurerm_private_dns_zone.this

  name                  = "link-hub-${replace(each.key, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# ─── Link zones to each Spoke VNet ───────────────────────────────
resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  for_each = {
    for pair in setproduct(keys(azurerm_private_dns_zone.this), keys(var.spoke_vnet_ids)) :
    "${pair[0]}|${pair[1]}" => {
      zone_name  = pair[0]
      spoke_name = pair[1]
      spoke_vnet = var.spoke_vnet_ids[pair[1]]
    }
  }

  name                  = "link-${each.value.spoke_name}-${replace(each.value.zone_name, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = each.value.zone_name
  virtual_network_id    = each.value.spoke_vnet
  registration_enabled  = false
  tags                  = var.tags
}