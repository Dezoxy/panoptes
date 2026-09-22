#!/usr/bin/env bash
#
# Bootstrap the Terraform state backend for the Panoptes Azure lab subscription.
#
# This is a script, not a Terraform resource, because of a chicken-and-egg problem:
# Terraform needs a backend to store its state before it can run, and it cannot create
# that backend as a managed resource inside the state it would then store there. The
# resource group, storage account and container created here sit outside Terraform's
# management for that reason. Everything else in iac/azure/ is a Terraform resource.
#
# Idempotent: safe to re-run. Azure resource creation calls succeed unchanged when the
# resource already exists with the same configuration; the role assignment is checked
# before it is created to avoid an "already exists" error.
#
# Usage:
#   SUBSCRIPTION_ID=<guid> ./bootstrap.sh [--location <region>] [--dry-run]
#   ./bootstrap.sh --subscription-id <guid> --location <region> --dry-run
#
# Inputs (env var or flag; flag wins when both are set):
#   SUBSCRIPTION_ID   Azure subscription id (GUID). Required.       Flag: --subscription-id
#   LOCATION          Azure region for the storage account.         Flag: --location
#                      Default: swedencentral
#   --dry-run         Print every az command instead of running it, then exit 0.
#                      Default: off.
#
# The resource group and storage account names below encode the Sweden Central region
# code ("swc") per the naming convention and are fixed regardless of --location; the
# state backend itself is not expected to move regions. --location only sets where the
# storage account is provisioned.
set -euo pipefail

DEFAULT_LOCATION="swedencentral"

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
LOCATION="${LOCATION:-$DEFAULT_LOCATION}"
DRY_RUN="false"

RESOURCE_GROUP="rg-panoptes-tfstate-swc"
CONTAINER_NAME="tfstate"
STORAGE_SKU="Standard_LRS"
ROLE_NAME="Storage Blob Data Contributor"

# Mandatory tags, per the platform tagging convention (docs/method and iac/azure/README.md).
TAGS=(
  "workload=panoptes"
  "environment=lab"
  "owner=ai-platform"
  "cost-centre=platform-lab"
  "managed-by=bootstrap-script"
)

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--subscription-id <guid>] [--location <region>] [--dry-run]

Creates the resource group, storage account and blob container that hold Panoptes'
Terraform state, and grants the signed-in user data-plane access to it.

  --subscription-id   Azure subscription id (GUID). Also read from SUBSCRIPTION_ID.
  --location           Azure region for the storage account. Default: swedencentral.
                        Also read from LOCATION.
  --dry-run             Print every az command instead of running it; exit 0.
  -h, --help            Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription-id)
      SUBSCRIPTION_ID="$2"
      shift 2
      ;;
    --location)
      LOCATION="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "SUBSCRIPTION_ID is required (env var or --subscription-id)." >&2
  usage >&2
  exit 1
fi

if [[ "$DRY_RUN" != "true" ]] && ! command -v az >/dev/null 2>&1; then
  echo "az CLI not found on PATH." >&2
  exit 1
fi

# run() is the single choke point every az invocation passes through, so --dry-run is
# honoured uniformly: in dry-run mode it only prints the command, and nothing that
# follows in the script ever executes a real Azure call.
run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'DRY-RUN: %q' "$1" >&2
    printf ' %q' "${@:2}" >&2
    printf '\n' >&2
    return 0
  fi
  "$@"
}

sha256_hex() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -d' ' -f1
  else
    shasum -a 256 | cut -d' ' -f1
  fi
}

SUBSCRIPTION_HASH="$(printf '%s' "$SUBSCRIPTION_ID" | sha256_hex | cut -c1-8)"

# Naming convention is stpanoptes<purpose><8-char-hash>; storage account names cannot
# exceed 24 characters. "stpanoptes" (10) + purpose "state" (5) + an 8-char hash is 23,
# which fits. The literal purpose "tfstate" would push this to 25 and Azure would
# refuse it, so the purpose is shortened to "state" here specifically.
STORAGE_ACCOUNT_NAME="stpanoptesstate${SUBSCRIPTION_HASH}"

echo "Resource group:   $RESOURCE_GROUP" >&2
echo "Storage account:  $STORAGE_ACCOUNT_NAME" >&2
echo "Location:         $LOCATION" >&2
echo >&2

run az account set --subscription "$SUBSCRIPTION_ID"

run az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags "${TAGS[@]}"

run az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku "$STORAGE_SKU" \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --allow-shared-key-access false \
  --https-only true \
  --tags "${TAGS[@]}"

run az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 30

STORAGE_ACCOUNT_ID="$(run az storage account show \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)"
if [[ "$DRY_RUN" == "true" ]]; then
  STORAGE_ACCOUNT_ID="<storage-account-resource-id>"
fi

SIGNED_IN_USER_ID="$(run az ad signed-in-user show --query id -o tsv)"
if [[ "$DRY_RUN" == "true" ]]; then
  SIGNED_IN_USER_ID="<signed-in-user-object-id>"
fi

# Data-plane RBAC, not a data-plane key: --allow-shared-key-access is false above, so
# the signed-in user needs this role to read and write blobs, including the container
# created below. Checked before creation because az role assignment create errors on
# a duplicate rather than treating it as a no-op.
EXISTING_ASSIGNMENT="$(run az role assignment list \
  --assignee "$SIGNED_IN_USER_ID" \
  --role "$ROLE_NAME" \
  --scope "$STORAGE_ACCOUNT_ID" \
  --query "[0].id" -o tsv)"

if [[ -z "$EXISTING_ASSIGNMENT" ]]; then
  run az role assignment create \
    --assignee "$SIGNED_IN_USER_ID" \
    --role "$ROLE_NAME" \
    --scope "$STORAGE_ACCOUNT_ID"
else
  echo "Role assignment already present, skipping." >&2
fi

# Newly granted RBAC can take up to a couple of minutes to propagate, and the
# container create below authenticates with Entra ID (--auth-mode login), so it is
# retried rather than failing the whole run on a transient 403.
CONTAINER_ATTEMPTS=6
CONTAINER_WAIT_SECS=10
container_created="false"
for ((attempt = 1; attempt <= CONTAINER_ATTEMPTS; attempt++)); do
  if run az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode login; then
    container_created="true"
    break
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    break
  fi
  echo "Container create failed, retrying (${attempt}/${CONTAINER_ATTEMPTS}) in ${CONTAINER_WAIT_SECS}s — likely RBAC propagation delay." >&2
  sleep "$CONTAINER_WAIT_SECS"
done

if [[ "$DRY_RUN" != "true" && "$container_created" != "true" ]]; then
  echo "ERROR: failed to create container '$CONTAINER_NAME' after ${CONTAINER_ATTEMPTS} attempts." >&2
  exit 1
fi

cat <<BACKEND >&2

Backend values for iac/azure/backend.tf and terraform init:

  resource_group_name  = "$RESOURCE_GROUP"
  storage_account_name  = "$STORAGE_ACCOUNT_NAME"
  container_name        = "$CONTAINER_NAME"
  key                    = "lab.tfstate"

Run:
  terraform init -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME"
BACKEND
