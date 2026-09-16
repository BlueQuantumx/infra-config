terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "nixcfgtfstate7867"
    container_name       = "tfstate"
    key                  = "tofu.tfstate"
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id == "" ? null : var.subscription_id
}

# Auth via the CLOUDFLARE_API_TOKEN environment variable
# (or CLOUDFLARE_API_KEY/CLOUDFLARE_EMAIL, or ~/.cloudflare/credentials)
provider "cloudflare" {}
