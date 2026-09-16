output "authkey_azure" {
  description = "Pre-authorized tailnet auth key for the azure node."
  value       = tailscale_tailnet_key.azure.key
  sensitive   = true
}

output "authkey_raspi" {
  description = "Pre-authorized tailnet auth key for the raspi node."
  value       = tailscale_tailnet_key.raspi.key
  sensitive   = true
}

output "authkey_mac" {
  description = "Pre-authorized tailnet auth key for the mac client node."
  value       = tailscale_tailnet_key.mac.key
  sensitive   = true
}

output "authkey_ios" {
  description = "Pre-authorized tailnet auth key for the iOS client node."
  value       = tailscale_tailnet_key.ios.key
  sensitive   = true
}

output "authkey_linux_desktop" {
  description = "Pre-authorized tailnet auth key for the Linux desktop client node."
  value       = tailscale_tailnet_key.linux_desktop.key
  sensitive   = true
}
