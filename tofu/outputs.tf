output "vm_public_ip" {
  description = "Public IP of the NixOS VM"
  value       = azurerm_public_ip.main.ip_address
}

output "ssh_command" {
  description = "SSH command to reach the deployed NixOS system"
  value       = "ssh root@${azurerm_public_ip.main.ip_address}"
}

output "resource_group_name" {
  description = "Azure resource group containing the VM"
  value       = azurerm_resource_group.main.name
}

output "entra_custom_domain" {
  description = "Microsoft Entra custom domain"
  value       = var.entra_custom_domain
}
