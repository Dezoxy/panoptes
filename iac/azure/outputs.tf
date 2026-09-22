output "resource_group_name" {
  description = "Name of the Panoptes lab resource group."
  value       = azurerm_resource_group.lab.name
}

output "resource_group_id" {
  description = "Resource id of the Panoptes lab resource group."
  value       = azurerm_resource_group.lab.id
}

output "names" {
  description = "Resolved resource names for this environment, per the naming convention in README.md."
  value       = local.names
}

output "budget_id" {
  description = "Resource id of the subscription consumption budget."
  value       = azurerm_consumption_budget_subscription.lab.id
}

output "key_vault_uri" {
  description = "URI of the Panoptes lab Key Vault."
  value       = azurerm_key_vault.lab.vault_uri
}

output "ai_services_endpoint" {
  description = "Endpoint of the Azure AI Foundry account. The key lives in Key Vault, not here."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "ai_services_deployment_names" {
  description = "Names of the Foundry model deployments this module manages."
  value = [
    azurerm_cognitive_deployment.gpt_4o.name,
  ]
}

output "app_insights_name" {
  description = "Name of the Application Insights resource. The connection string lives in Key Vault, not here."
  value       = azurerm_application_insights.lab.name
}

output "monitor_workspace_id" {
  description = "Resource id of the Azure Monitor managed Prometheus workspace."
  value       = azurerm_monitor_workspace.lab.id
}

output "monitor_workspace_query_endpoint" {
  description = "Query endpoint of the Azure Monitor managed Prometheus workspace."
  value       = azurerm_monitor_workspace.lab.query_endpoint
}

output "entra_group_object_ids" {
  description = "Object ids of the Panoptes entitlement groups, keyed by group display name."
  value = {
    (azuread_group.research.display_name)         = azuread_group.research.object_id
    (azuread_group.client_reporting.display_name) = azuread_group.client_reporting.object_id
    (azuread_group.platform.display_name)         = azuread_group.platform.object_id
  }
}

output "gateway_app_client_id" {
  description = "Client id of the panoptes-gateway app registration, for consumers requesting a token."
  value       = azuread_application.gateway.client_id
}

output "container_apps_environment_id" {
  description = "Resource id of the Container Apps environment."
  value       = azurerm_container_app_environment.lab.id
}

output "gateway_fqdn" {
  description = "Public HTTPS URL of the panoptes-gateway Container App."
  value       = "https://${azapi_resource.gateway.output.properties.configuration.ingress.fqdn}"
}

output "gateway_principal_id" {
  description = "Object id of the gateway Container App's system-assigned managed identity, e.g. for granting it access to a resource this module does not manage."
  value       = azurerm_user_assigned_identity.gateway.principal_id
}

output "container_registry_login_server" {
  description = "Login server (hostname) of the Panoptes lab container registry, for image references and `docker login`/`az acr login`."
  value       = azurerm_container_registry.lab.login_server
}

output "github_actions_client_id" {
  description = "Client id of the github-actions-panoptes app registration. Not a secret — this is the identifier the GitHub Actions OIDC exchange presents; see README.md for the repository variables it feeds."
  value       = azuread_application.github_actions.client_id
}
