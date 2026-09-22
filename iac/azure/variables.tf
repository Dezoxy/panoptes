variable "subscription_id" {
  description = "Azure subscription id this module deploys into."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a GUID, e.g. 00000000-0000-0000-0000-000000000000."
  }
}

variable "location" {
  description = "Primary Azure region. Sweden Central, for model availability (ADR-0002)."
  type        = string
  default     = "swedencentral"
}

variable "environment" {
  description = "Environment name used in resource naming."
  type        = string
  default     = "lab"
}

variable "workload" {
  description = "Workload name used in resource naming and the mandatory workload tag."
  type        = string
  default     = "panoptes"
}

variable "tags" {
  description = "Mandatory tags applied to every resource this module creates."
  type        = map(string)
  default = {
    workload      = "panoptes"
    environment   = "lab"
    owner         = "ai-platform"
    "cost-centre" = "platform-lab"
    "managed-by"  = "terraform"
  }
}

variable "budget_amount" {
  description = "Monthly subscription budget amount (ADR-0005: 30 EUR cap)."
  type        = number
  default     = 30
}

# No budget_currency variable: azurerm_consumption_budget_subscription always reports in
# the subscription's billing currency — EUR, for a Hungarian billing account — so there
# is nothing for a variable to set.

variable "alert_emails" {
  description = "Email addresses notified by the budget's spend alerts."
  type        = list(string)
}

variable "budget_start_date" {
  description = "Start of the budget's first period, RFC3339, first day of a month. Fixed so plans do not churn monthly."
  type        = string
  default     = "2026-09-01T00:00:00Z"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "budget_start_date must be the first day of a month at midnight UTC, e.g. 2026-09-01T00:00:00Z."
  }
}

variable "always_on" {
  description = "ADR-0005: sets minimum replicas to one for the gateway when responsiveness matters (e.g. a measurement window), and back to zero otherwise. Cold starts distort latency numbers, so this is a deliberate, temporary switch, not a standing setting."
  type        = bool
  default     = false
}

variable "gateway_image" {
  description = "Container image for the panoptes-gateway Container App, in the lab's own registry (owner decision: no public image, no registry password). `main` is the lab tag, pushed by GitHub Actions on every push to main; pin a sha256 digest tag before any pilot with real consumer traffic (ADR-0005 exit-path and canary reasoning applies to the image too, not just LiteLLM config)."
  type        = string
  default     = "crpanopteslabswc.azurecr.io/panoptes-gateway:sha-3765c15"
}

variable "otel_collector_image" {
  description = "Container image for the OpenTelemetry collector sidecar. Tag verified to exist on Docker Hub (otel/opentelemetry-collector-contrib) at the time this was written; bump deliberately, not on every plan."
  type        = string
  default     = "otel/opentelemetry-collector-contrib:0.161.0"
}

variable "break_glass_object_id" {
  description = "Entra object id of the personal Microsoft account kept as break-glass (billing owner, Global Administrator, not used day to day) — see operators.tf. Retrieve while signed in as that account with `az ad signed-in-user show --query id -o tsv` and set it in lab.auto.tfvars (gitignored); it cannot default to data.azurerm_client_config.current.object_id because that value tracks whichever account is signed in to the CLI at plan time, which is exactly the drift this variable exists to stop."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.break_glass_object_id))
    error_message = "break_glass_object_id must be a GUID, e.g. 00000000-0000-0000-0000-000000000000."
  }
}

variable "tenant_id" {
  description = "Entra tenant the lab lives in. Pinned on every provider so the CLI default account cannot redirect an apply."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a GUID."
  }
}
