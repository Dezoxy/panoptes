# GitHub Actions workload identity federation (OIDC): no long-lived Azure credential
# is stored in GitHub, ever. GitHub mints a short-lived OIDC token scoped to the
# workflow run; Entra ID trades it for an Azure access token via the federated
# credentials below, matched on the token's issuer and subject claims.
#
# One credential only, for pushes to main. Pull-request runs build the image without
# pushing and never need Azure, so they get no identity at all: a pull_request subject
# would let any PR (a fork included, until branch protection is reviewed) obtain a token
# for a principal that holds AcrPush. Even the main credential grants nothing beyond
# that role assignment; no subscription-level access exists yet.

resource "azuread_application" "github_actions" {
  display_name     = "github-actions-panoptes"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_application_federated_identity_credential" "github_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-main"
  description    = "GitHub Actions: pushes to main on Dezoxy/panoptes (builds and pushes the gateway image)."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:Dezoxy/panoptes:ref:refs/heads/main"
}

# Push access to the gateway image's registry — nothing else. A read-only
# `terraform plan` from CI (a Reader role, subscription or resource group scope) is a
# later step: this identity does not get it here, because granting read access ahead
# of the workflow that would use it is scope nobody has asked for yet.
resource "azurerm_role_assignment" "github_actions_acr_push" {
  scope                = azurerm_container_registry.lab.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github_actions.object_id
}
