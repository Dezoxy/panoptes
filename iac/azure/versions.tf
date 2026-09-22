terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    # azurerm 4.81 cannot express Container Apps serviceBinds (verified against the
    # provider's container_app docs at that pinned version); azapi manages the
    # PostgreSQL add-on and the gateway app instead. Pinned to the current stable 2.x
    # release, verified against the Terraform Registry.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}
