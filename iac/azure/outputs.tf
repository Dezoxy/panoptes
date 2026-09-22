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
