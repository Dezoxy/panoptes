# The state backend itself is bootstrapped by iac/azure/bootstrap/bootstrap.sh, not by
# this module — Terraform cannot create the backend it needs in order to run. See the
# header comment in bootstrap.sh for why.
#
# storage_account_name is deliberately not set here: it carries a hash derived from the
# subscription id (so it stays globally unique without being guessable), and bootstrap.sh
# prints the value it created. Supply it at init time instead:
#
#   terraform init -backend-config="storage_account_name=<from bootstrap.sh output>"
terraform {
  backend "azurerm" {
    resource_group_name = "rg-panoptes-tfstate-swc"
    container_name      = "tfstate"
    key                 = "lab.tfstate"
    use_azuread_auth    = true
  }
}
