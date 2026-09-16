variable "subscription_id" {
  description = "Azure subscription ID. Defaults to the az cli/current subscription when empty."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the state resources."
  type        = string
  default     = "eastasia"
}

variable "storage_account_name" {
  description = "Globally unique storage account name for tfstate."
  type        = string
  default     = "nixcfgtfstate7867"
}
