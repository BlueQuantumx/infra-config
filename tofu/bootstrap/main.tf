terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id == "" ? null : var.subscription_id
}

resource "azurerm_resource_group" "state" {
  name     = "rg-tfstate"
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account" "state" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "state" {
  name                 = "tfstate"
  storage_account_id   = azurerm_storage_account.state.id
}

resource "azurerm_management_lock" "state" {
  name       = "tfstate-can-not-delete"
  scope      = azurerm_resource_group.state.id
  lock_level = "CanNotDelete"
}

output "storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "resource_group_name" {
  value = azurerm_resource_group.state.name
}
