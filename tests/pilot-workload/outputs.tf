output "vm_name" {
  description = "Test VM name"
  value       = azurerm_linux_virtual_machine.pilot.name
}

output "vm_id" {
  description = "Test VM resource ID (needed for Bastion)"
  value       = azurerm_linux_virtual_machine.pilot.id
}

output "vm_private_ip" {
  description = "VM private IP (from NIC)"
  value       = azurerm_network_interface.pilot.private_ip_address
}

output "vm_identity_principal_id" {
  description = "VM Managed Identity principal ID"
  value       = azurerm_linux_virtual_machine.pilot.identity[0].principal_id
}

output "admin_username" {
  value = var.admin_username
}

output "admin_password" {
  description = "VM admin password (sensitive — never commit)"
  value       = random_password.admin.result
  sensitive   = true
}

output "bastion_ssh_command" {
  description = "Command to SSH into the VM via Bastion"
  value       = "az network bastion ssh --name bastion-hub --resource-group ${local.hub_rg_name} --target-resource-id ${azurerm_linux_virtual_machine.pilot.id} --auth-type password --username ${var.admin_username}"
}