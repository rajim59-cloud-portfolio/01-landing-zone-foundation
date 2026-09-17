output "vm_private_ip" {
  description = "Private IP of the pilot VM"
  value       = azurerm_network_interface.pilot_vm_nic.private_ip_address
}

output "vm_id" {
  description = "Resource ID of the pilot VM"
  value       = azurerm_linux_virtual_machine.pilot_vm.id
}

output "ssh_private_key" {
  description = "Private key for Bastion SSH authentication"
  value       = tls_private_key.vm_ssh.private_key_pem
  sensitive   = true
}