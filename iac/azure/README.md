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
- Key Vault, RBAC-authorised, with the signed-in operator granted `Key Vault Secrets
  Officer` (`keyvault.tf`).
- The Azure AI Foundry account and its two model deployments, Sweden Central
  (`foundry.tf`). See the secrets table below for where the key and endpoint land.
- Log Analytics, workspace-based Application Insights and the Azure Monitor managed
  Prometheus workspace (`observability.tf`).
- Three Entra ID security groups standing in for consumer teams, and the
  `panoptes-gateway` app registration with its `Gateway.Consumer` app role
  (`entra.tf`).

Public network access is enabled on Key Vault and the Foundry account for this step,
each with a `#checkov:skip` recording why: the production placement (ADR-0002) uses a
private endpoint, which the on-prem gateway cannot reach until it runs inside the
Azure VNet.

## Key Vault secrets

| Secret | Written by | Read by |
| --- | --- | --- |
| `foundry-api-key` | `foundry.tf`, from the Foundry account's primary key | LiteLLM (`../../gateway/`), until Entra-only auth replaces the key |
| `foundry-endpoint` | `foundry.tf`, from the Foundry account | LiteLLM (`../../gateway/`) |
| `appinsights-connection-string` | `observability.tf`, from the Application Insights resource | The gateway's OpenTelemetry collector sidecar, once it exists |

## What later steps add

The Container Apps environment and the `panoptes-gateway` and Ollama Container Apps;
the Container Apps PostgreSQL add-on; the OpenTelemetry collector sidecar; the Grafana
Container App; the `panoptes-meter` scheduled job. See ADR-0005 for the full
placement.

## Bootstrap and init sequence

State lives in Azure Storage, addressed with Entra ID (`use_azuread_auth = true`, no
storage account keys). The storage account cannot be a Terraform resource — Terraform
needs it to exist before it can store anything — so it is created once by a script.

1. **Once per subscription** — create the state backend:

   ```sh
   SUBSCRIPTION_ID=<guid> make bootstrap
   ```

   Creates the state resource group, storage account and container, registers the
   resource providers Phase 1 needs, and writes `lab.tfbackend` (gitignored) with the
   backend values so nothing is copied by hand. Rerunning it is safe. Run the script
   with `--dry-run` to see the `az` commands before anything is created.

2. **Initialise** against the backend file:

   ```sh
   make init
   ```

3. **Plan**, saved to `lab.tfplan` (gitignored) so apply runs exactly what was read:

   ```sh
   make plan
   ```

4. **Apply is run by the platform owner, locally, after reading the plan** (`make apply`). Never from
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

Arrives with the gateway step (Phase 1, step 3). It sets minimum replicas to one for the
gateway and Grafana when responsiveness matters and back to zero afterwards (ADR-0005).
It is not declared yet: unused variables fail tflint, so variables are added when used.
