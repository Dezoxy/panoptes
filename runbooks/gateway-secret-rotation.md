# Runbook: rotating a gateway secret

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-22
- **Out of scope** — rotating the Terraform state storage access; rotating the GitHub
  federation (no secret exists there); provider-side key lifecycle in the vendor console.

## When

A provider API key, the Application Insights connection string or the LiteLLM master key
changes in Key Vault. Applies to every secret the gateway reads through a Key Vault
reference (`iac/azure/container_apps.tf`, `secrets`).

## What does not work

Restarting the active revision does **not** re-resolve Key Vault references. Verified on
2026-09-22: a new secret version was written, the revision was restarted, and the gateway
kept using the previous value. References are resolved when a revision is created.

## Procedure

1. Write the new version to Key Vault with the silent prompt in `iac/azure/README.md`, or
   with `az keyvault secret set`. Never paste the value into a shell history.
2. Roll a new revision. Either apply a Terraform change that touches the template (the
   image pin in `var.gateway_image` is the normal trigger), or, for a rotation with no
   other change:

   ```sh
   az containerapp revision copy \
     --name ca-panoptes-gateway-lab-swc \
     --resource-group rg-panoptes-lab-swc \
     --revision-suffix "rot$(date -u +%H%M)"
   ```

3. Wait for the new revision to report `Healthy` and take 100 % of traffic, then confirm
   the route that uses the secret answers:

   ```sh
   az containerapp revision list -n ca-panoptes-gateway-lab-swc -g rg-panoptes-lab-swc \
     --query "[].{name:name, health:properties.healthState, traffic:properties.trafficWeight}" -o table
   ```

4. Disable the previous secret version in Key Vault once the new revision is serving, so
   a rollback to the old revision fails loudly rather than silently using a revoked key.

## Evidence

The Key Vault secret version list (`az keyvault secret list-versions`) and the revision
list are the two records that show when the rotation happened and which revision picked
it up. Neither contains the secret value.
