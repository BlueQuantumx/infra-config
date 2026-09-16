resource "azurerm_resource_group" "main" {
  name     = var.name_prefix
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.name_prefix}-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

  # EasyTier mesh (optional fallback): tcp/udp listener, WireGuard transport and
  # WireGuard client portal. Only created when the mesh is enabled; port values
  # still come from defaults.nix via terraform.tfvars.json.
  dynamic "security_rule" {
    for_each = var.enable_easytier ? [
      {
        name     = "EasyTier-TCP"
        priority = 140
        protocol = "Tcp"
        ports    = var.easy_tier_tcp_ports
      },
      {
        name     = "EasyTier-UDP"
        priority = 141
        protocol = "Udp"
        ports    = var.easy_tier_udp_ports
      },
    ] : []

    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_ranges    = [for p in security_rule.value.ports : tostring(p)]
      source_address_prefixes    = ["0.0.0.0/0"]
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "main" {
  # The revision suffix gives the replacement PIP a unique name so it can be
  # created while the old one is still attached to the NIC. Bump
  # var.public_ip_revision (via tofu/defaults.nix azure.publicIpRevision) to
  # rotate to a new static IP with zero manual steps.
  name                = "${var.name_prefix}-pip-${var.public_ip_revision}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  # Create the new PIP, repoint the NIC/DNS, then drop the old one. Without
  # this, Azure rejects the delete because the old PIP is still allocated to
  # the NIC (`PublicIPAddressCannotBeDeleted`).
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "main" {
  name                = "${var.name_prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "${var.name_prefix}-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_file))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = true
}

resource "cloudflare_record" "substore" {
  zone_id = data.cloudflare_zone.personal.id
  name    = var.subdomain_substore
  content = azurerm_public_ip.main.ip_address
  type    = "A"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "azure" {
  zone_id = data.cloudflare_zone.personal.id
  name    = var.subdomain_azure
  content = azurerm_public_ip.main.ip_address
  type    = "A"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "navidrome" {
  zone_id = data.cloudflare_zone.personal.id
  name    = var.subdomain_navidrome
  content = azurerm_public_ip.main.ip_address
  type    = "A"
  proxied = false
  ttl     = 1
}

resource "null_resource" "entra_domain" {
  triggers = {
    domain_name = var.entra_custom_domain
  }

  provisioner "local-exec" {
    command = <<-EOT
      if ! az rest --method GET --url "https://graph.microsoft.com/v1.0/domains/${var.entra_custom_domain}" >/dev/null 2>&1; then
        az rest --method POST \
          --url "https://graph.microsoft.com/v1.0/domains" \
          --body '{"id":"${var.entra_custom_domain}"}' >/dev/null
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "az rest --method DELETE --url \"https://graph.microsoft.com/v1.0/domains/${self.triggers.domain_name}\""
  }
}

data "cloudflare_zone" "personal" {
  name = var.domain_personal
}
