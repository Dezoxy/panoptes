# Operator entry point for the Azure lab module. Every target runs from this directory.
# apply is deliberately interactive and never run from CI (ADR-0004; working rule).

SHELL := /bin/bash
# Panoptes keeps its own Azure CLI profile so a login for other Azure work on this machine
# cannot change the account Terraform uses. Override by exporting AZURE_CONFIG_DIR.
export AZURE_CONFIG_DIR ?= $(HOME)/.azure-panoptes
.DEFAULT_GOAL := help
BACKEND_FILE := lab.tfbackend
TFVARS := lab.auto.tfvars

.PHONY: help login bootstrap init plan apply fmt validate check

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

login: ## Sign in to the lab tenant inside the Panoptes CLI profile
	az login --tenant $$(awk -F'"' '/^tenant_id/{print $$2}' lab.auto.tfvars)
	az account set --subscription $$(awk -F'"' '/^subscription_id/{print $$2}' lab.auto.tfvars)

bootstrap: ## One-time: create the state storage account and write lab.tfbackend
	@[[ -n "$$SUBSCRIPTION_ID" ]] || { echo "SUBSCRIPTION_ID is required" >&2; exit 1; }
	bash bootstrap/bootstrap.sh

$(BACKEND_FILE):
	@echo "$(BACKEND_FILE) is missing. Run: SUBSCRIPTION_ID=<id> make bootstrap" >&2; exit 1

$(TFVARS):
	@echo "$(TFVARS) is missing. Copy lab.auto.tfvars.example and fill it in." >&2; exit 1

init: $(BACKEND_FILE) ## terraform init against the bootstrapped backend
	terraform init -backend-config=$(BACKEND_FILE)

plan: $(BACKEND_FILE) $(TFVARS) ## Read-only plan
	terraform plan -out=lab.tfplan

apply: $(BACKEND_FILE) $(TFVARS) ## Apply the last saved plan, after reading it
	@[[ -f lab.tfplan ]] || { echo "No saved plan. Run: make plan" >&2; exit 1; }
	terraform apply lab.tfplan
	@rm -f lab.tfplan

fmt: ## Format
	terraform fmt -recursive

validate: ## Offline validation (no backend)
	terraform init -backend=false -input=false >/dev/null && terraform validate

check: fmt validate ## Format and validate
