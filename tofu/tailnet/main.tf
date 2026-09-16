locals {
  # Role tags, applied to nodes through their auth keys.
  tag_server = "tag:server"
  tag_exit   = "tag:exit"
  tag_client = "tag:client"
}

resource "tailscale_acl" "policy" {
  acl = <<-ACL
    {
      "tagOwners": {
        "${local.tag_server}": ["autogroup:admin"],
        "${local.tag_exit}": ["autogroup:admin"],
        "${local.tag_client}": ["autogroup:admin"]
      },
      "autoApprovers": {
        "exitNode": ["${local.tag_exit}"]
      },
      "grants": [
        { "src": ["*"], "dst": ["*"], "ip": ["*"] }
      ],
      "ssh": [
        {
          "action": "check",
          "src": ["autogroup:member"],
          "dst": ["autogroup:self"],
          "users": ["autogroup:nonroot", "root"]
        }
      ]
    }
  ACL

  # The tailnet already has the default policy; take ownership of it without a
  # separate import step.
  overwrite_existing_content = true
}

resource "tailscale_dns_preferences" "this" {
  magic_dns = true
}

# One pre-authorized, reusable key per node. Tags ride on the key, so nodes are
# classified (and exit nodes auto-approved) at enrollment with no later lookup.
resource "tailscale_tailnet_key" "azure" {
  reusable            = true
  ephemeral           = false
  preauthorized       = true
  expiry              = var.auth_key_expiry_seconds
  recreate_if_invalid = "always"
  description         = "azureserverexit"
  tags                = [local.tag_server, local.tag_exit]
}

resource "tailscale_tailnet_key" "raspi" {
  reusable            = true
  ephemeral           = false
  preauthorized       = true
  expiry              = var.auth_key_expiry_seconds
  recreate_if_invalid = "always"
  description         = "raspiserverexit"
  tags                = [local.tag_server, local.tag_exit]
}

resource "tailscale_tailnet_key" "mac" {
  reusable            = true
  ephemeral           = false
  preauthorized       = true
  expiry              = var.auth_key_expiry_seconds
  recreate_if_invalid = "always"
  description         = "macclient"
  tags                = [local.tag_client]
}

resource "tailscale_tailnet_key" "ios" {
  reusable            = true
  ephemeral           = false
  preauthorized       = true
  expiry              = var.auth_key_expiry_seconds
  recreate_if_invalid = "always"
  description         = "iosclient"
  tags                = [local.tag_client]
}

resource "tailscale_tailnet_key" "linux_desktop" {
  reusable            = true
  ephemeral           = false
  preauthorized       = true
  expiry              = var.auth_key_expiry_seconds
  recreate_if_invalid = "always"
  description         = "linuxdesktopclient"
  tags                = [local.tag_client]
}
