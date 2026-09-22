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
    ai_services                = "ais-${local.name_prefix}"

    # Container Apps, per the README naming table: ca-<workload>-<component>-<environment>-<region>.
    gateway_container_app  = "ca-${var.workload}-gateway-${var.environment}-${local.region_code}"
    gateway_identity       = "id-${var.workload}-gateway-${var.environment}-${local.region_code}"
    postgres_container_app = "ca-${var.workload}-postgres-${var.environment}-${local.region_code}"

    # Container registries cannot take hyphens (same constraint as storage accounts,
    # documented in README.md's naming convention section): cr<workload><environment><region>.
    container_registry = "cr${var.workload}${var.environment}${local.region_code}"
  }
}
