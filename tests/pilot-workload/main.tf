# ================================================================
# Local values — pulled from landing zone remote state
# ================================================================
locals {
  lz = data.terraform_remote_state.landing_zone.outputs

  spoke_app_rg      = local.lz.spoke_app_resource_group_name
  app_subnet_id     = local.lz.spoke_app_app_subnet_id
  law_id            = local.lz.log_analytics_workspace_id
  hub_rg_name       = local.lz.hub_resource_group_name

  vm_name = "vm-pilot-test"
  nic_name = "nic-pilot-test"
}

# ================================================================
# Random password for VM admin (never hardcoded, never in Git)
# ================================================================
resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
}

# ================================================================
# Network Interface — NO public IP (this is deliberate)
# ================================================================
resource "azurerm_network_interface" "pilot" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = local.spoke_app_rg
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.app_subnet_id
    private_ip_address_allocation = "Dynamic"
    # ⚠️ NO public_ip_address_id — Bastion required for access
  }
}

# ================================================================
# Linux VM — Standard_B1s (cheapest, no premium features)
# ================================================================
resource "azurerm_linux_virtual_machine" "pilot" {
  name                  = local.vm_name
  location              = var.location
  resource_group_name   = local.spoke_app_rg
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.pilot.id]
  tags                  = var.tags

  admin_password                  = random_password.admin.result
  disable_password_authentication = false

  # ─── Managed Identity — no secrets needed to access Key Vault ───
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # ─── Boot diagnostics for troubleshooting ────────────────────
  boot_diagnostics {}
}

# ================================================================
# Diagnostic Settings — send VM metrics to central LAW
# ================================================================
resource "azurerm_monitor_diagnostic_setting" "pilot_vm" {
  name                       = "diag-pilot-vm"
  target_resource_id         = azurerm_linux_virtual_machine.pilot.id
  log_analytics_workspace_id = local.law_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}