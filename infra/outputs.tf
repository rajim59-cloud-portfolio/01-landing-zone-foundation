# ================================================================
# These outputs are consumed by Project 2, 3, 4, etc.
# ================================================================

output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = module.hub_network.hub_vnet_id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = module.hub_network.hub_vnet_name
}

output "firewall_private_ip" {
  description = "Firewall private IP"
  value       = module.hub_network.firewall_private_ip
}

output "spoke_app_subnet_ids" {
  description = "App spoke subnet IDs"
  value       = module.spoke_app.subnet_ids
}

output "spoke_data_subnet_ids" {
  description = "Data spoke subnet IDs"
  value       = module.spoke_data.subnet_ids
}

output "resource_group_names" {
  description = "All resource group names"
  value = {
    hub        = module.hub_network.resource_group_name
    spoke_app  = module.spoke_app.resource_group_name
    spoke_data = module.spoke_data.resource_group_name
  }
}

output "log_analytics_workspace_id" {
  description = "Central Log Analytics Workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "cloud_engineers_group_id" {
  description = "cloud-engineers group object ID"
  value       = module.identity.cloud_engineers_group_id
}
output "spoke_app_app_subnet_id" {
  description = "App subnet ID in Spoke-App (consumed by pilot workloads)"
  value       = module.spoke_app.subnet_ids["app"]
}

output "hub_resource_group_name" {
  description = "Hub resource group name"
  value       = module.hub_network.resource_group_name
}

output "spoke_app_resource_group_name" {
  description = "Spoke-App resource group name"
  value       = module.spoke_app.resource_group_name
}
output "private_dns_zone_ids" {
  description = "Private DNS zone IDs"
  value       = module.private_dns.zone_ids
}