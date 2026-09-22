# Azure-native observability path (ADR-0005): the on-prem Loki/Tempo/Prometheus stack
# stays documented rather than run, because three always-on replicas would consume the
# whole 30 EUR monthly cap before a single model call. Logs and traces land in
# Application Insights over this Log Analytics workspace; metrics go to the managed
# Prometheus workspace below by remote write once the gateway's OpenTelemetry collector
# exists.

resource "azurerm_log_analytics_workspace" "lab" {
  name                = local.names.log_analytics
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Workspace-based: the older, disconnected Application Insights resource is
# deprecated, and this is the only mode current API versions support cleanly.
resource "azurerm_application_insights" "lab" {
  name                = local.names.app_insights
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  workspace_id        = azurerm_log_analytics_workspace.lab.id
  application_type    = "web"

  # Sampling is disabled on the client side (ADR-0005: "a sampled-away audit record is
  # not an audit record"). Nothing here can enforce that from the collector side — it
  # is the OpenTelemetry collector sidecar's config, in ../../gateway/, that must set
  # a sampling ratio of 1.0 when it is added.

  tags = var.tags
}

resource "azurerm_monitor_workspace" "lab" {
  name                = local.names.monitor_workspace
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location

  tags = var.tags
}

# Lab tier: same reasoning as the Foundry secrets in foundry.tf.
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  # checkov:skip=CKV_AZURE_41: same reasoning as the Foundry secrets in foundry.tf — no
  # rotation policy exists yet for the lab tier, and a fixed expiry nothing here checks
  # is worse than none.
  name         = "appinsights-connection-string"
  value        = azurerm_application_insights.lab.connection_string
  key_vault_id = azurerm_key_vault.lab.id
  content_type = "text/plain"

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}
