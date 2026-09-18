# ================================================================
# Root Module — wires up all child modules
# ================================================================

# ─── Hub Network (shared platform) ───────────────────────────────
module "hub_network" {
  source = "./modules/hub-network"

  location = var.location
  tags     = var.tags

  hub_vnet_cidr               = var.hub_vnet_cidr
  firewall_subnet_cidr        = "10.0.1.0/26"
  firewall_mgmt_subnet_cidr   = "10.0.5.0/26"
  bastion_subnet_cidr         = "10.0.2.0/26"
  gateway_subnet_cidr         = "10.0.3.0/27"
  shared_services_subnet_cidr = "10.0.4.0/24"
}

# ─── Spoke: App ──────────────────────────────────────────────────
module "spoke_app" {
  source = "./modules/spoke-network"

  name     = "app"
  location = var.location
  tags     = var.tags

  vnet_cidr = var.spoke_app_vnet_cidr
  subnets = {
    app  = { name = "AppSubnet", address_prefix = "10.1.1.0/24" }
    func = { name = "FunctionSubnet", address_prefix = "10.1.2.0/24" }
  }

  # Route Data spoke CIDR explicitly to firewall (fixes LPM bypass)
  remote_spoke_cidrs = [var.spoke_data_vnet_cidr]

  hub_vnet_id             = module.hub_network.hub_vnet_id
  hub_vnet_name           = module.hub_network.hub_vnet_name
  hub_resource_group_name = module.hub_network.resource_group_name
  hub_vnet_cidr           = var.hub_vnet_cidr
  bastion_subnet_cidr     = "10.0.2.0/26"
  firewall_private_ip     = module.hub_network.firewall_private_ip
}

# ─── Spoke: Data ─────────────────────────────────────────────────
module "spoke_data" {
  source = "./modules/spoke-network"

  name     = "data"
  location = var.location
  tags     = var.tags

  vnet_cidr = var.spoke_data_vnet_cidr
  subnets = {
    data = { name = "DataSubnet", address_prefix = "10.2.1.0/24" }
    pe   = { name = "PrivateEndpointSubnet", address_prefix = "10.2.2.0/24" }
  }

  # Route App spoke CIDR explicitly to firewall (fixes LPM bypass)
  remote_spoke_cidrs = [var.spoke_app_vnet_cidr]

  hub_vnet_id             = module.hub_network.hub_vnet_id
  hub_vnet_name           = module.hub_network.hub_vnet_name
  hub_resource_group_name = module.hub_network.resource_group_name
  hub_vnet_cidr           = var.hub_vnet_cidr
  bastion_subnet_cidr     = "10.0.2.0/26"
  firewall_private_ip     = module.hub_network.firewall_private_ip
}

# ─── Policy (governance) ─────────────────────────────────────────
module "policy" {
  source = "./modules/policy"

  scope_id          = var.subscription_id
  allowed_locations = [var.location]
  required_tags     = ["CostCenter", "Env", "Owner"]
}

# ─── Identity ─────────────────────────────────────────────────────
module "identity" {
  source = "./modules/identity"

  tenant_id                      = data.azurerm_client_config.current.tenant_id
  subscription_id                = var.subscription_id
  hub_resource_group_name        = module.hub_network.resource_group_name
  spoke_app_resource_group_name  = module.spoke_app.resource_group_name
  spoke_data_resource_group_name = module.spoke_data.resource_group_name
}

# ─── Monitoring ───────────────────────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  location          = var.location
  tags              = var.tags
  alert_email       = var.alert_email
  budget_amount_usd = var.budget_amount_usd

  firewall_resource_id = module.hub_network.firewall_id
  bastion_resource_id  = module.hub_network.bastion_id
  spoke_app_vnet_id    = module.spoke_app.vnet_id
  spoke_data_vnet_id   = module.spoke_data.vnet_id
}

# ─── Management Groups (CAF Hierarchy — Enterprise Architecture Design) ───
# Kept as code/design standard. Requires Tenant Root Group write permissions
# in multi-subscription enterprise tenants.
# module "management_groups" {
#   source = "./modules/management-groups"
#
#   root_management_group_id   = data.azurerm_client_config.current.tenant_id
#   platform_subscription_ids  = [var.subscription_id]
#   workloads_subscription_ids = []
#   sandbox_subscription_ids   = []
# }

# ─── Private DNS Zones ───────────────────────────────────────────
module "private_dns" {
  source = "./modules/private-dns"

  location                = var.location
  tags                    = var.tags
  hub_resource_group_name = module.hub_network.resource_group_name
  hub_vnet_id             = module.hub_network.hub_vnet_id
  spoke_vnet_ids = {
    app  = module.spoke_app.vnet_id
    data = module.spoke_data.vnet_id
  }
}

# ─── Defender for Cloud (Foundational CSPM Free Tier) ───────────
module "defender" {
  source = "./modules/defender"

  alert_email            = var.alert_email
  enable_servers_pricing = false
  enable_cspm            = false
}