// The system in scope and its containers. Groups are the platform layers from
// the repository README, so a reader can map a box to the layer that owns it.
//
// The base puts the system's inbound and outbound relationships in this file;
// Panoptes keeps them in relationships.dsl instead, because most of them cross
// layers and reading them layer by layer hid the call paths.

panoptes = softwareSystem "Panoptes" "The shared AI platform: one way in to a model, one place that decides what a consumer may do, and one record of what it did and what it cost." {

    group "Model gateway" {
        gateway = container "panoptes-gateway" "Single ingress for model traffic. Routes by data class and model, falls back between providers, enforces per-key quotas and rate limits, and emits the audit record for every call." "LiteLLM proxy, Python" "Layer Gateway,Gateway"
        configStore = container "Gateway config store" "Routing table, fallback chains, quota and rate-limit definitions. Config as code: changed by pull request in this repository, rendered into the cluster." "Git, rendered to a Kubernetes ConfigMap" "Layer Gateway"
    }

    group "Controls plane" {
        policies = container "panoptes-policies" "Decides whether a call is allowed: maps data classification to the providers that may see it, and checks the caller's entitlement." "Open Policy Agent, Rego" "Layer Controls"
        entitlements = container "Entitlement source" "The Entra ID security groups that grant a consumer a model, a data class and a budget. Owned by the platform, held in the tenant." "Microsoft Entra ID security groups" "Layer Controls"
        secretStore = container "Secret store" "Provider API keys and signing material. No credential is held in the gateway configuration or in this repository." "Azure Key Vault" "Layer Controls,Vault"
        evidence = container "Evidence collector" "Collects what a control actually did — policy decisions, rule versions, onboarding records — so a review reads evidence rather than intent." "Python" "Layer Controls"
    }

    group "Telemetry and FinOps" {
        meter = container "panoptes-meter" "Turns token and request usage into cost attributed to a consumer, a model and a workload. The number a budget is measured against." "Python" "Layer Telemetry"
        otel = container "OpenTelemetry collector" "Single collection point for traces, metrics and logs leaving the gateway. Fans them out to the stores and to the cost pipeline." "OpenTelemetry Collector" "Layer Telemetry"
        loki = container "Loki" "Log and audit-record store." "Grafana Loki" "Layer Telemetry,Storage"
        tempo = container "Tempo" "Trace store." "Grafana Tempo" "Layer Telemetry,Storage"
        grafana = container "Grafana" "Dashboards, budgets and alerting for spend, quota and gateway health." "Grafana" "Layer Telemetry"
    }

    group "Lifecycle" {
        cli = container "panoptes CLI" "Operator entry point: onboard a workload, set a budget, collect evidence, administer the Copilot estate." "Python, panoptes_platform" "Layer Lifecycle"
        register = container "Onboarding register" "Record per workload of intake, risk tier and lifecycle stage. The answer to who is using what, and under which review." "Git, YAML records" "Layer Lifecycle"
    }

    group "Consumer surfaces" {
        portal = container "Self-service portal" "Where a consumer requests access, sees their entitlement and watches their spend against budget." "Web application" "Layer Surfaces,Web UI"
        docsSite = container "Developer documentation site" "How to call the gateway, which model suits which data class, and what a consumer is expected to do. docs.panoptes.northgate.internal" "Static site" "Layer Surfaces,Web UI"
    }
}
