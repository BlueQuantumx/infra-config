variable "auth_key_expiry_seconds" {
  description = "Lifetime of minted tailnet auth keys, in seconds."
  type        = number
  default     = 7776000 # 90 days
}
