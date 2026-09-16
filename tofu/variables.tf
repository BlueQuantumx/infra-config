# Variables are required: values are injected by the auto-loaded
# terraform.tfvars.json, generated from tofu/defaults.nix with
# `nix run .#tofu-vars`. Run `nix run .#tofu-plan` / `nix run .#tofu-apply`
# to regenerate before applying. The only exception is subscription_id, which
# comes from the gitignored terraform.tfvars.
variable "subscription_id" {
  description = "Azure subscription ID. Leave empty to use the one from `az login`."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all Azure resource names"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size. The free tier offers 750h/month of B1s, B2pts_v2 (ARM) and B2ats_v2 (AMD). B2ats_v2 is the x86_64 option."
  type        = string
}

variable "admin_username" {
  description = "Username of the temporary Ubuntu VM used by nixos-anywhere for the installation"
  type        = string
}

variable "ssh_public_key_file" {
  description = "Path to the SSH public key installed on the VM and the final NixOS system"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to the matching SSH private key used by nixos-anywhere to install and update NixOS"
  type        = string
}

variable "domain_personal" {
  description = "Cloudflare zone (domain) to create the sub-store A record in"
  type        = string
}

variable "entra_custom_domain" {
  description = "Microsoft Entra custom domain to register"
  type        = string
}

variable "subdomain_substore" {
  description = "Subdomain name for the sub-store A record, e.g. `sub` -> sub.<zone>"
  type        = string
}

variable "subdomain_azure" {
  description = "Subdomain name for the azure A record, e.g. `azure` -> azure.<zone>"
  type        = string
}

variable "subdomain_navidrome" {
  description = "Subdomain name for the navidrome A record, e.g. `navidrome` -> navidrome.<zone>"
  type        = string
}

variable "enable_easytier" {
  description = "Create the EasyTier NSG rules for the optional fallback mesh"
  type        = bool
}

variable "easy_tier_tcp_ports" {
  description = "TCP ports to open for the EasyTier mesh (only used when enable_easytier)"
  type        = list(number)
}

variable "easy_tier_udp_ports" {
  description = "UDP ports to open for the EasyTier mesh (only used when enable_easytier)"
  type        = list(number)
}

variable "public_ip_revision" {
  description = "Bump to rotate the Azure public IP. Appended to the PIP name so the new IP is allocated before the old one is released (create_before_destroy)."
  type        = number
  default     = 1
}
