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

variable "location_secondary" {
  description = "Documented failover region (ADR-0002). Not provisioned by this module."
  type        = string
  default     = "westeurope"
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

variable "always_on" {
  description = <<-EOT
    Reserved for a later step. When true, the gateway and Grafana Container Apps
    (ADR-0005) run with a minimum of one replica instead of scaling to zero. This
    module does not yet create any Container Apps, so the value has no effect here.
  EOT
  type        = bool
  default     = false
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
