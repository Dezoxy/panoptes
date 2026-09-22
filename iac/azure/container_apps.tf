# The Container Apps environment, the PostgreSQL development-tier add-on and the
# panoptes-gateway app (ADR-0005). The gateway runs LiteLLM (ADR-0003) with an
# OpenTelemetry collector sidecar; the collector's own config file lives in
# ../../gateway/otel/collector.yaml, authored on a parallel branch — see the
# fileexists() guard below.
#
# azurerm 4.81 (pinned in versions.tf) has no serviceBinds argument on
# azurerm_container_app — verified against that version's own provider docs, not the
# latest ones. The PostgreSQL add-on service is a Microsoft.App/containerApps resource
# in its own right (properties.configuration.service.type = "postgres"), and only the
# azapi provider can express the serviceBinds array a consumer needs to attach to it.
# Both Container Apps in this file go through azapi rather than splitting the shape
# between two providers for one feature.
#
# Resource shape (Service, ServiceBind, Configuration, Container, Ingress, Volume)
# verified against the Microsoft.App/containerApps ContainerApps.json swagger schema
# in Azure/azure-rest-api-specs (specification/app/resource-manager/Microsoft.App/
# ContainerApps/stable/). The service is now on 2026-07-01, but azapi 2.12.0's
# embedded schema validator only recognises up to 2026-01-01 (verified: it rejects
# 2026-07-01 with the list of versions it accepts) — pinned to 2026-01-01 for that
# reason; both versions define the same fields used here.

# The gateway image's own registry: no public image, no registry password (owner
# decision, superseding the earlier public-ghcr.io plan). The gateway pulls with its
# user-assigned identity (AcrPull, below); GitHub Actions pushes with workload
# identity federation (github_actions.tf) — no static credential exists anywhere in
# the image path, from build to running container.
resource "azurerm_container_registry" "lab" {
  name                = local.names.container_registry
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  sku                 = "Basic"

  # Pull and push both go through Entra managed identities (AcrPull, AcrPush below),
  # never the registry's own admin account.
  admin_enabled = false

  # checkov:skip=CKV_AZURE_139: lab tier; same reasoning as Key Vault and Foundry in
  # keyvault.tf and foundry.tf — the production placement (ADR-0002) uses a private
  # endpoint, which neither the gateway nor the GitHub Actions runner can reach until
  # they run inside the Azure VNet. Basic SKU also cannot take a network_rule_set
  # (Premium-only), so a Deny-by-default rule set is not an option at this tier either.
  public_network_access_enabled = true

  # The six skips below are all Premium-SKU or Defender-for-Containers features.
  # Premium is roughly 10x Basic's price (Azure retail pricing, Sweden Central,
  # verified 2026-09-22) — real money against ADR-0005's 30 EUR monthly cap for one
  # low-traffic image with a single consumer (the gateway app itself). Revisit
  # alongside ADR-0005 if the registry ever serves more than that one image, or a
  # supply-chain requirement (signed images, mandatory scanning) is written down
  # somewhere that isn't this comment.
  # checkov:skip=CKV_AZURE_233: zone redundancy is Premium-only.
  # checkov:skip=CKV_AZURE_167: retention policies for untagged manifests are Premium-only.
  # checkov:skip=CKV_AZURE_164: content trust (signed images) is Premium-only.
  # checkov:skip=CKV_AZURE_165: geo-replication is Premium-only and there is nothing to
  # replicate to — Sweden Central is the only region this module deploys into.
  # checkov:skip=CKV_AZURE_166: quarantine/scan-on-push is Premium-only.
  # checkov:skip=CKV_AZURE_163: vulnerability scanning needs Microsoft Defender for
  # Containers, a separate paid add-on this module does not enable.
  # checkov:skip=CKV_AZURE_237: dedicated data endpoints are Premium-only.

  tags = var.tags
}

resource "azurerm_container_app_environment" "lab" {
  name                       = local.names.container_apps_environment
  resource_group_name        = azurerm_resource_group.lab.name
  location                   = azurerm_resource_group.lab.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.lab.id
  logs_destination           = "log-analytics"

  # No workload_profile block: omitting it keeps the environment Consumption-only
  # (azurerm_container_app_environment docs, v4.81.0 — "Defining a Consumption profile
  # is optional"), which is what ADR-0005 decided and is also the only way to get
  # scale-to-zero. Adding a named profile later forces recreation of the environment.

  tags = var.tags
}

# LiteLLM's own master key (virtual keys, teams and spend logs are authenticated
# against it). Generated rather than operator-supplied, unlike the three provider keys
# below: nothing external needs to know it in advance, so there is no reason to make a
# human type 48 random characters into Key Vault by hand. It transits Terraform state
# in plaintext, same accepted exposure as the Foundry key in foundry.tf, guarded the
# same way (Entra-only state storage, no shared key access).
resource "random_password" "litellm_master_key" {
  length  = 48
  special = false
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_key_vault_secret" "litellm_master_key" {
  # checkov:skip=CKV_AZURE_41: lab tier; same reasoning as the Foundry secrets in
  # foundry.tf — no rotation policy exists yet, and a fixed expiry nothing here checks
  # is worse than none. Rotating this means re-running Terraform (random_password
  # replaces on `terraform taint`, not silently).
  name         = "litellm-master-key"
  value        = random_password.litellm_master_key.result
  key_vault_id = azurerm_key_vault.lab.id
  content_type = "text/plain"

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

# The gateway/otel/collector.yaml file is authored on a parallel branch and may not
# exist yet when this is planned. A placeholder keeps `terraform plan` and `apply`
# working either way; the collector sidecar will not run correctly until the real
# file lands and this is re-applied. The operator step for that is in README.md.
locals {
  otel_collector_config_path   = "${path.module}/../../gateway/otel/collector.yaml"
  otel_collector_config_exists = fileexists(local.otel_collector_config_path)
  otel_collector_config        = local.otel_collector_config_exists ? file(local.otel_collector_config_path) : <<-EOT
    # PLACEHOLDER — gateway/otel/collector.yaml did not exist when this was planned.
    # Re-run `make plan` / `make apply` once the gateway branch adds the real file;
    # until then the otel-collector sidecar has no working pipeline.
    receivers: {}
    exporters: {}
    service:
      pipelines: {}
  EOT

  # LiteLLM needs one DATABASE_URL; the Postgres add-on injects separate
  # POSTGRES_HOST/PORT/USERNAME/PASSWORD/DATABASE variables instead (the add-on's
  # contract — see README.md and learn.microsoft.com "Container Apps add-on
  # services"). Composed here instead of in the image so the image stays add-on
  # agnostic.
  gateway_entrypoint = "export DATABASE_URL=postgresql://$POSTGRES_USERNAME:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE && exec litellm --config /app/config.yaml --port 4000"
}

# The Container Apps PostgreSQL add-on, development tier (ADR-0005: "not for
# production data" — virtual keys, teams and spend logs only, all re-creatable from
# ../../gateway/). No SLA, no backups by default; see the ADR's risk register.
resource "azapi_resource" "postgres" {
  type      = "Microsoft.App/containerApps@2026-01-01"
  name      = local.names.postgres_container_app
  parent_id = azurerm_resource_group.lab.id
  location  = azurerm_resource_group.lab.location

  body = {
    properties = {
      environmentId = azurerm_container_app_environment.lab.id
      configuration = {
        service = {
          type = "postgres"
        }
      }
    }
  }

  tags = var.tags
}

# The gateway's identity is user-assigned and created before the app, with its roles
# already granted, because a system-assigned identity only exists once the app does and
# the app cannot pull its image (AcrPull) or resolve its Key Vault references (Secrets
# User) until the roles land: the first revision never becomes healthy and provisioning
# hangs until it times out. Granting first, then creating, removes the ordering problem.
resource "azurerm_user_assigned_identity" "gateway" {
  name                = local.names.gateway_identity
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "gateway_kv_secrets_user" {
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gateway.principal_id
}

resource "azurerm_role_assignment" "gateway_acr_pull" {
  scope                = azurerm_container_registry.lab.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.gateway.principal_id
}

resource "azapi_resource" "gateway" {
  type      = "Microsoft.App/containerApps@2026-01-01"
  name      = local.names.gateway_container_app
  parent_id = azurerm_resource_group.lab.id
  location  = azurerm_resource_group.lab.location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gateway.id]
  }

  # Roles are granted to the identity before the app exists (see above), so the first
  # revision can pull and resolve secrets. Role propagation can still lag by a minute.
  depends_on = [
    azurerm_role_assignment.gateway_kv_secrets_user,
    azurerm_role_assignment.gateway_acr_pull,
  ]

  body = {
    properties = {
      environmentId = azurerm_container_app_environment.lab.id
      configuration = {
        activeRevisionsMode = "Single"

        # Pulls with the gateway's user-assigned identity, not a registry password.
        # "system" (lower-case) is the literal value RegistryCredentials.identity
        # expects for a system-assigned identity — verified in the same swagger this
        # file already cites; note it differs in casing from Secret.identity's
        # "System" above, which is the API's own inconsistency, not a typo here.
        # Same chicken-and-egg as the Key Vault role below: the AcrPull role only
        # exists once this app's identity does, so the first revision may need a
        # restart once it has propagated (README.md).
        registries = [
          {
            server   = azurerm_container_registry.lab.login_server
            identity = azurerm_user_assigned_identity.gateway.id
          },
        ]

        # HTTPS only: allowInsecure = false redirects HTTP to HTTPS rather than
        # accepting it. Public ingress is deliberate for the lab tier (ADR-0005 has
        # no VNet placement yet; see the same trade-off recorded on Key Vault and
        # Foundry in keyvault.tf and foundry.tf).
        ingress = {
          external      = true
          targetPort    = 4000
          transport     = "auto"
          allowInsecure = false
        }

        # Key Vault references resolve at revision activation using this app's own
        # identity — but that identity does not get the Key Vault Secrets User role
        # until azurerm_role_assignment.gateway_kv_secrets_user, below, which can only
        # be created after this app (and its identity) exists. The first revision's
        # secrets will fail to resolve; restarting it once the role has propagated is
        # a manual operator step, documented in README.md.
        secrets = [
          {
            name        = "foundry-api-key"
            keyVaultUrl = "${azurerm_key_vault.lab.vault_uri}secrets/foundry-api-key"
            identity    = azurerm_user_assigned_identity.gateway.id
          },
          {
            name        = "appinsights-connection-string"
            keyVaultUrl = "${azurerm_key_vault.lab.vault_uri}secrets/appinsights-connection-string"
            identity    = azurerm_user_assigned_identity.gateway.id
          },
          {
            name        = "litellm-master-key"
            keyVaultUrl = "${azurerm_key_vault.lab.vault_uri}secrets/litellm-master-key"
            identity    = azurerm_user_assigned_identity.gateway.id
          },
          # The three secrets below are written by the operator, by hand, never by
          # Terraform — see README.md for the exact `az keyvault secret set` commands.
          # This module only reads their URL, never their value.
          {
            name        = "anthropic-api-key"
            keyVaultUrl = "${azurerm_key_vault.lab.vault_uri}secrets/anthropic-api-key"
            identity    = azurerm_user_assigned_identity.gateway.id
          },
          {
            name        = "openai-api-key"
            keyVaultUrl = "${azurerm_key_vault.lab.vault_uri}secrets/openai-api-key"
            identity    = azurerm_user_assigned_identity.gateway.id
          },
          {
            name        = "openrouter-api-key"
            keyVaultUrl = "${azurerm_key_vault.lab.vault_uri}secrets/openrouter-api-key"
            identity    = azurerm_user_assigned_identity.gateway.id
          },
          # Not a Key Vault reference: the collector's own config file content,
          # mounted as a volume below. See the fileexists() guard above.
          {
            name  = "otel-collector-config"
            value = local.otel_collector_config
          },
        ]
      }

      template = {
        containers = [
          {
            name    = "litellm"
            image   = var.gateway_image
            command = ["sh", "-c", local.gateway_entrypoint]

            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }

            env = [
              { name = "AZURE_API_BASE", value = azurerm_cognitive_account.foundry.endpoint },
              { name = "AZURE_API_KEY", secretRef = "foundry-api-key" },         # pragma: allowlist secret
              { name = "ANTHROPIC_API_KEY", secretRef = "anthropic-api-key" },   # pragma: allowlist secret
              { name = "OPENAI_API_KEY", secretRef = "openai-api-key" },         # pragma: allowlist secret
              { name = "OPENROUTER_API_KEY", secretRef = "openrouter-api-key" }, # pragma: allowlist secret
              # Step 4 (not yet built): Ollama as a scale-to-zero Container App. The
              # name follows the same convention as gateway/postgres above; nothing
              # resolves it until that step lands.
              { name = "OLLAMA_API_BASE", value = "http://ca-panoptes-ollama-lab-swc" },
              { name = "LITELLM_MASTER_KEY", secretRef = "litellm-master-key" }, # pragma: allowlist secret
              { name = "OTEL_EXPORTER_OTLP_ENDPOINT", value = "http://localhost:4318" },
            ]

            probes = [
              {
                type = "Liveness"
                httpGet = {
                  path = "/health/liveliness"
                  port = 4000
                }
              },
              {
                type = "Readiness"
                httpGet = {
                  path = "/health/readiness"
                  port = 4000
                }
              },
            ]
          },
          {
            name  = "otel-collector"
            image = var.otel_collector_image
            args  = ["--config=/etc/otelcol/config.yaml"]

            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }

            env = [
              { name = "APPLICATIONINSIGHTS_CONNECTION_STRING", secretRef = "appinsights-connection-string" }, # pragma: allowlist secret
            ]

            volumeMounts = [
              { volumeName = "otel-collector-config", mountPath = "/etc/otelcol" },
            ]
          },
        ]

        volumes = [
          {
            name        = "otel-collector-config"
            storageType = "Secret"
            secrets = [
              { secretRef = "otel-collector-config", path = "config.yaml" }, # pragma: allowlist secret
            ]
          },
        ]

        # ADR-0005: minReplicas 0 by default (consumption plan, scale-to-zero);
        # always_on flips it to 1 for a measurement window. maxReplicas 2 is
        # headroom, not a capacity plan — there is no load-testing basis for it yet.
        scale = {
          minReplicas = var.always_on ? 1 : 0
          maxReplicas = 2
        }

        serviceBinds = [
          { serviceId = azapi_resource.postgres.id, name = "postgres" },
        ]
      }
    }
  }

  tags = var.tags

  response_export_values = ["properties.configuration.ingress.fqdn"]
}
