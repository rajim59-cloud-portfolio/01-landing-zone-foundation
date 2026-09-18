output "zone_ids" {
  description = "Map of zone name → zone ID"
  value = {
    for name, zone in azurerm_private_dns_zone.this : name => zone.id
  }
}

output "zone_names" {
  value = keys(azurerm_private_dns_zone.this)
}