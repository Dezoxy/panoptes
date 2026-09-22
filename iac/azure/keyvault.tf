# Key Vault holds the secrets later steps write: the Foundry account key and endpoint,
# and the Application Insights connection string. RBAC authorisation, not access
# policies, so who can read a secret is governed the same way as every other role
# assignment in this module.

data "azurerm_client_config" "current" {}

# Lab tier: soft delete (90 days) and purge protection already guard against
# accidental loss; a hard Terraform-level lock would block the teardown ADR-0005's
# cost cap assumes stays available, for a resource re-created fresh by `terraform
# apply` if it is ever removed.
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_key_vault" "lab" {
  # checkov:skip=CKV2_AZURE_32: lab tier; the production placement uses a private
  # endpoint (ADR-0002), same reason as the public-access and network-ACL skips below.
  name                = local.names.key_vault
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

  # Soft delete cannot be disabled on current API versions; 90 days is the maximum
  # retention window, chosen deliberately rather than left at a shorter default.
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # TLS/HTTPS-only access is the provider default and is not overridden here.

  # checkov:skip=CKV_AZURE_189: lab tier; the production placement uses a private
  # endpoint (ADR-0002). Public access is required for now because the on-prem
  # gateway cannot reach a private endpoint from outside the Azure VNet.
  public_network_access_enabled = true

  network_acls {
    # checkov:skip=CKV_AZURE_109: lab tier; the production placement uses a private
    # endpoint (ADR-0002). Default Allow matches the public access decision above —
    # a Deny default with no IP rules configured would just block everything anyway.
    #trivy:ignore:AVD-AZU-0013
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Lets the signed-in operator (and, later, workloads granted the same role) manage
# secret values without falling back to the legacy access-policy model.
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
