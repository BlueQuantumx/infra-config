resource "null_resource" "nixos_anywhere" {
  triggers = {
    instance_id = azurerm_linux_virtual_machine.main.id
  }

  provisioner "local-exec" {
    command = "nixos-anywhere --build-on remote --flake \"${path.module}/../..#azure\" ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
  }
}
