# Azure root module

- **Owner** — AI Platform / Security
- **Status** — Draft
- **Last reviewed** — 2026-09-22
- **Out of scope** — the on-prem Kubernetes manifests, which are Documented per
  [ADR-0005](../../adr/0005-lab-tier-on-azure.md) rather than deployed anywhere; the
  gateway application itself, which lives in `../../gateway/`.

Terraform for the Panoptes Azure lab subscription (ADR-0002, ADR-0005): Sweden Central
primary, West Europe as the documented failover, on Azure Container Apps.

## What this manages today

- The lab resource group (`azurerm_resource_group`).
- A subscription-wide consumption budget with alerts at 50% and 90% actual spend and
  100% forecast spend (`azurerm_consumption_budget_subscription`).
- A tag policy assignment on the resource group, denying a resource that is missing
  any of the five mandatory tags (`policy.tf`).

Nothing else exists yet. `locals.tf` resolves the names later steps will use — Key
Vault, the Container Apps environment, Log Analytics, Application Insights, the Azure
Monitor workspace — so every step follows the same naming convention from the start,
even though this step creates none of them.

## What later steps add

Key Vault; the two Azure AI Foundry model deployments (Sweden Central); Entra app
registrations; the Container Apps environment and the `panoptes-gateway` and Ollama
Container Apps; the Container Apps PostgreSQL add-on; the OpenTelemetry
collector/Application Insights/Azure Monitor managed Prometheus observability path;
the Grafana Container App; the `panoptes-meter` scheduled job. See ADR-0005 for the
full placement.

## Bootstrap and init sequence

State lives in Azure Storage, addressed with Entra ID (`use_azuread_auth = true`, no
storage account keys). The storage account cannot be a Terraform resource — Terraform
needs it to exist before it can store anything — so it is created once by a script.

1. **Once per subscription** — create the state backend:

   ```sh
   SUBSCRIPTION_ID=<guid> ./bootstrap/bootstrap.sh
   ```

   This prints the storage account name it created (see `bootstrap/bootstrap.sh` for
   what it does and why). Run it with `--dry-run` first if you want to see the `az`
   commands before anything is created.

2. **Initialise, with the storage account name from step 1**:

   ```sh
   terraform init -backend-config="storage_account_name=<from bootstrap.sh output>"
   ```

3. **Plan**:

   ```sh
   terraform plan
   ```

4. **Apply is run by the platform owner, locally, after reading the plan.** Never from
   CI — ADR-0004 keeps CI read-only, and the working rule in `CLAUDE.md` is that
   nothing is deployed on this platform's behalf without a human reading the plan
   first.

Copy `lab.auto.tfvars.example` to `lab.auto.tfvars` (gitignored — `*.tfvars`) and fill
in `subscription_id` and `alert_emails` before running `plan`.

## Naming convention

Cloud Adoption Framework style: `<resource-type>-<workload>-<environment>-<region>`.
Storage accounts cannot take hyphens, so they follow
`st<workload><purpose><8-char-hash>` instead, with the hash derived from the
subscription id so the globally-unique name stays reproducible without being
guessable.

| Region | Code |
| --- | --- |
| Sweden Central | `swc` |
| West Europe | `weu` |

| Resource | Example name |
| --- | --- |
| Resource group | `rg-panoptes-lab-swc` |
| Key Vault | `kv-panoptes-lab-swc` |
| Container Apps environment | `cae-panoptes-lab-swc` |
| Container App (gateway) | `ca-panoptes-gateway-lab-swc` |
| Terraform state storage account | `stpanoptesstate<8-char-hash>` |

## Tags

Every resource this module creates carries all five:

| Tag | Value |
| --- | --- |
| `workload` | `panoptes` |
| `environment` | `lab` |
| `owner` | `ai-platform` |
| `cost-centre` | `platform-lab` |
| `managed-by` | `terraform` |

`policy.tf` enforces this inside the resource group; nothing here checks the state
resource group `bootstrap.sh` creates, which is tagged by the script itself instead.

## `always_on`

Reserved for the step that adds the gateway and Grafana Container Apps. Defaults to
`false` (scale to zero, per ADR-0005). Set to `true` only for the duration of a
measurement window where cold starts would distort latency numbers, then back to
`false` — an always-on replica of either app is ongoing spend against the 30 EUR cap.
