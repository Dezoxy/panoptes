provider "azurerm" {
  features {}

  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id
  storage_use_azuread = true
}

# Every provider is pinned to the tenant, and azapi to the subscription, so the Azure
# CLI's default account cannot redirect an apply. On 2026-09-22 the CLI default moved to
# an unrelated tenant mid-session; an unpinned azuread provider would have created the
# admin user and its Global Administrator role there.
provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azapi" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
