terraform {
  required_version = ">= 1.6.0"

  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.29"
    }
  }

  # Reuses the same remote backend as the Azure stack, under its own state key
  # so tailnet policy changes never touch the Azure VM state.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "nixcfgtfstate7867"
    container_name       = "tfstate"
    key                  = "tailnet.tfstate"
  }
}

# Auth via TAILSCALE_OAUTH_CLIENT_ID / TAILSCALE_OAUTH_CLIENT_SECRET in the
# environment (or TAILSCALE_API_KEY). No credential is committed or generated.
provider "tailscale" {}
