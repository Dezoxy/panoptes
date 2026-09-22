# Operator identities for the Panoptes lab tenant (azuretomhorvath.onmicrosoft.com,
# tenant 00f1b6c6-e44f-42cd-95fd-d0fd61c67825).
#
# The tenant was operated day to day through a personal Microsoft account,
# azure@tomhorvath.me, which consumer fraud protection locked once. Decision: create a
# work account for daily administration and keep the personal account as break-glass —
# billing owner, Global Administrator, not used day to day. See README.md's "Operator
# identities" section for the operator-facing setup steps.
#
# Both operators need the same standing access (Key Vault Secrets Officer, membership
# in sg-panoptes-platform), granted below with a single for_each over
# local.platform_operators rather than two near-identical resource blocks per grant.
#
# Stability note: the two grants this replaces (kv_secrets_officer in keyvault.tf,
# platform_current_user in entra.tf) used to target data.azurerm_client_config.current
# / data.azuread_client_config.current — the object id of whoever is signed in to the
# CLI at plan time. Once the work account exists and daily administration moves to it,
# that CLI switch would have silently moved both grants off the break-glass account
# with no diff calling it out as a change worth reading. local.platform_operators
# below names both principals explicitly instead, so a plan run under either account
# grants the same fixed set.

locals {
  platform_operators = {
    break_glass = var.break_glass_object_id
    admin       = azuread_user.admin.object_id
  }
}

# The two grants above are moved here, not recreated: the resource addresses are
# unchanged (kv_secrets_officer, platform_current_user), only for_each has been added,
# with the pre-existing bare instance re-keyed to "break_glass". Without these blocks
# Terraform would plan to destroy the existing assignment/membership and create two new
# ones — `make plan` was run to confirm no destroy is planned (see the pull request).
moved {
  from = azurerm_role_assignment.kv_secrets_officer
  to   = azurerm_role_assignment.kv_secrets_officer["break_glass"]
}

moved {
  from = azuread_group_member.platform_current_user
  to   = azuread_group_member.platform_current_user["break_glass"]
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  for_each             = local.platform_operators
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

resource "azuread_group_member" "platform_current_user" {
  for_each         = local.platform_operators
  group_object_id  = azuread_group.platform.object_id
  member_object_id = each.value
}

# The work admin account itself. usage_location is required before a licence can ever
# be assigned to it and Hungary matches where this tenant is administered from.
resource "random_password" "admin_initial" {
  length  = 32
  special = true
}

resource "azuread_user" "admin" {
  user_principal_name   = "admin@azuretomhorvath.onmicrosoft.com"
  display_name          = "Panoptes Platform Administrator"
  password              = random_password.admin_initial.result
  force_password_change = true
  usage_location        = "HU"
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_key_vault_secret" "admin_initial_password" {
  # checkov:skip=CKV_AZURE_41: lab tier; same reasoning as the Foundry and LiteLLM
  # secrets in foundry.tf and container_apps.tf — no rotation policy exists yet at
  # this tier. This secret is read exactly once, by the operator completing the work
  # account's first sign-in (README.md's "Operator identities" section), which also
  # disables this version straight after — an expiry date nothing here checks would
  # add nothing.
  name         = "admin-initial-password"
  value        = random_password.admin_initial.result
  key_vault_id = azurerm_key_vault.lab.id
  content_type = "initial password, rotate on first sign-in"

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

# Global Administrator: template_id is Microsoft's fixed identifier for the built-in
# role, constant across every tenant, not something this module generates. Creating
# this resource activates the role in this tenant if it is not active already.
resource "azuread_directory_role" "global_administrator" {
  template_id = "62e90394-69f5-4237-9190-012177145e10"
}

# A production tenant would make both of these grants below PIM-eligible — activated
# on demand, time-bound, with justification recorded — rather than standing
# assignments. Not available on this lab tenant's licence: Entra ID PIM for directory
# roles needs Entra ID P2 / Microsoft 365 E5, and this subscription has neither.
# Revisit if the tenant is ever licensed for P2.
resource "azuread_directory_role_assignment" "admin_global_administrator" {
  role_id             = azuread_directory_role.global_administrator.template_id
  principal_object_id = azuread_user.admin.object_id
}

resource "azurerm_role_assignment" "admin_subscription_owner" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azuread_user.admin.object_id
}
