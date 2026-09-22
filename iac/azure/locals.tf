locals {
  # Cloud Adoption Framework region codes for the two regions ADR-0002 names.
  region_codes = {
    swedencentral = "swc"
    westeurope    = "weu"
  }

  region_code = local.region_codes[var.location]
  name_prefix = "${var.workload}-${var.environment}-${local.region_code}"

  # Names for this step's resource group plus the resources later steps add, so that
  # every step names things the same way instead of each inventing its own prefix.
  names = {
    resource_group             = "rg-${local.name_prefix}"
    key_vault                  = "kv-${local.name_prefix}"
    container_apps_environment = "cae-${local.name_prefix}"
    log_analytics              = "log-${local.name_prefix}"
    app_insights               = "appi-${local.name_prefix}"
    monitor_workspace          = "amw-${local.name_prefix}"
  }
}
