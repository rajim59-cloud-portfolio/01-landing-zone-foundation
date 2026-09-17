terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- Azure Native Data Source: Fetch Spoke App Subnet Directly ---
data "azurerm_subnet" "spoke_app" {
  name                 = "AppSubnet"
  virtual_network_name = "vnet-spoke-app"
  resource_group_name  = "rg-spoke-app"
}

# --- SSH Key Generation (No hardcoded credentials) ---
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# --- NIC (No Public IP - Fully Private) ---
resource "azurerm_network_interface" "pilot_vm_nic" {
  name                = "nic-pilot-vm"
  location            = var.location
  resource_group_name = "rg-spoke-app"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.spoke_app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    CostCenter = "portfolio-01"
    Env        = "dev"
    Owner      = "rajim"
    Project    = "pilot-workload"
  }
}

# --- Linux Virtual Machine ---
resource "azurerm_linux_virtual_machine" "pilot_vm" {
  name                = "vm-pilot-app"
  resource_group_name = "rg-spoke-app"
  location            = var.location
  size                = "Standard_D2s_v4"
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.pilot_vm_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    CostCenter = "portfolio-01"
    Env        = "dev"
    Owner      = "rajim"
    Project    = "pilot-workload"
  }
}