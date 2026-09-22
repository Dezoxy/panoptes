# Enforcement half of the tagging convention documented in README.md: a resource
# missing any of the five mandatory tags is denied at creation inside this resource
# group. The equivalent subscription-level assignment is deferred until the state
# resource group and storage account (created by bootstrap.sh, outside Terraform) are
# also tagged and that assignment has been reviewed — assigning it now would cover
# resources this module does not manage and cannot verify.

data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

resource "azurerm_resource_group_policy_assignment" "require_tag" {
  for_each = var.tags

  name                 = "require-tag-${each.key}"
  resource_group_id    = azurerm_resource_group.lab.id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id

  parameters = jsonencode({
    tagName = {
      value = each.key
    }
  })
}
