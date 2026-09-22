resource "azurerm_resource_group" "lab" {
  name     = local.names.resource_group
  location = var.location
  tags     = var.tags
}

# Consumption budget for the whole subscription, not just this resource group: token
# spend and any other subscription activity both count against the 30 EUR cap
# ADR-0005 imposes, so scoping the budget to one resource group would miss the rest.
resource "azurerm_consumption_budget_subscription" "lab" {
  name            = "budget-${local.name_prefix}"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    # A fixed date: deriving it from the plan time would change on the first of every
    # month and force the budget to be replaced. It only needs to be in the past.
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 50
    threshold_type = "Actual"
    contact_emails = var.alert_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 90
    threshold_type = "Actual"
    contact_emails = var.alert_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 100
    threshold_type = "Forecasted"
    contact_emails = var.alert_emails
  }
}
