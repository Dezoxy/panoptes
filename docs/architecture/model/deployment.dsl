// Where the containers run. Placement is hybrid, so the three environments the
// platform spans — Azure, the on-prem cluster and the provider APIs — are
// modelled as top-level deployment nodes of one environment rather than as
// separate deploymentEnvironment blocks. One view then shows the whole estate
// and the boundaries it crosses, which is the question the reader has.
//
// ADR-0005 moves the lab tier off the on-prem cluster and into the Azure lab
// subscription on Container Apps. The Azure node therefore holds the runtime as
// well as the control plane, and the on-prem node holds nothing that runs: it
// is the documented exit environment.
//
// The base models one environment per deploymentEnvironment block because its
// environments are copies of each other; these are not.
//
// People are not deployable elements, so the consumer network holds the
// endpoint they work from, not the people themselves.

deploymentEnvironment "Platform" {

    deploymentNode "Consumer network" "Managed endpoints on the corporate network. No consumer reaches a provider directly." "Northgate corporate network" {

        deploymentNode "Managed workstation" "Entra-joined, compliant device. The only place the CLI runs." "Windows or macOS, Intune managed" {
            containerInstance panoptes.cli
        }

        softwareSystemInstance zeroTrustProxy
    }

    azure = deploymentNode "Azure subscription (Sweden Central)" "sub-panoptes-lab. Holds the control plane and, since ADR-0005, the lab tier itself. Sweden Central primary, West Europe secondary (ADR-0002); no model data leaves the EU." "Microsoft Azure" "Azure" {

        deploymentNode "Identity plane" "Northgate workforce tenant. Not a per-subscription resource; drawn here because it is the Azure-side identity boundary." "Microsoft Entra ID" {
            softwareSystemInstance entraId
            containerInstance panoptes.entitlements
        }

        foundry = deploymentNode "Azure AI Foundry" "Hosted model deployments. Sweden Central primary; West Europe secondary." "Azure AI Foundry" {
            foundryInstance = softwareSystemInstance aiFoundry
        }

        deploymentNode "kv-panoptes-weu" "RBAC mode, private endpoint, purge protection on." "Azure Key Vault" {
            containerInstance panoptes.secretStore
        }

        // The lab tier (ADR-0005). Consumption plan: every app scales to zero
        // unless the Terraform variable always_on pins it to one replica, which
        // is what a 30 EUR monthly cap affords.
        cae = deploymentNode "Container Apps environment (cae-panoptes-lab)" "Consumption plan, scale-to-zero by default. always_on pins the gateway and Grafana to one replica for a measurement window." "Azure Container Apps" {

            gatewayApp = deploymentNode "panoptes-gateway" "One Container App. The OpenTelemetry collector runs as a sidecar in the same app, so telemetry leaves with the revision that produced it." "Container App" {
                gw = containerInstance panoptes.gateway
                containerInstance panoptes.configStore
                otel = containerInstance panoptes.otel
            }

            postgres = infrastructureNode "PostgreSQL add-on" "Development tier: no SLA, no backups by default. LiteLLM virtual keys, teams and spend logs only — nothing in it is a system of record (ADR-0005)." "Azure Container Apps PostgreSQL add-on"

            policiesApp = deploymentNode "panoptes-policies" "Sidecar-free; the gateway calls it over the environment network." "Container App" {
                containerInstance panoptes.policies
            }

            meterJob = deploymentNode "panoptes-meter" "Scheduled job rather than a service: cost attribution runs on a timer, not per request." "Container Apps job" {
                meter = containerInstance panoptes.meter
            }

            evidenceJob = deploymentNode "panoptes-evidence" "Scheduled job. Collects what a control did, for review." "Container Apps job" {
                evidence = containerInstance panoptes.evidence
            }

            grafanaApp = deploymentNode "grafana" "Scale-to-zero Container App. Azure Managed Grafana was rejected on cost (ADR-0005)." "Container App" {
                grafana = containerInstance panoptes.grafana
            }

            deploymentNode "lifecycle" "Records and consumer-facing surfaces." "Container App" {
                containerInstance panoptes.register
                containerInstance panoptes.portal
                containerInstance panoptes.docsSite
            }

            deploymentNode "model-runtime" "Scale-to-zero Container App, CPU only, model baked into the image. Own-tenancy, so the tier 3 provider rule is unchanged; vLLM on GPU stays the documented production alternative (ADR-0002)." "Container App" {
                softwareSystemInstance selfHostedRuntime
            }
        }

        // Azure-native observability replaces the self-hosted Loki, Tempo and
        // Prometheus of the original plan in the lab (ADR-0005). Subscription
        // resources, not Container Apps resources, so they sit beside cae.
        appInsights = infrastructureNode "Application Insights / Log Analytics" "Logs, traces and the audit record. Sampling is off: a sampled-away audit record is not an audit record (ADR-0005)." "Azure Monitor"

        prometheus = infrastructureNode "Azure Monitor managed Prometheus" "Platform, gateway and cost metrics, held in an Azure Monitor workspace." "Azure Monitor managed Prometheus"

        // Documented, not running. The dashed border is the whole point: it says
        // the design was written down, not that the control is in force.
        apim = infrastructureNode "APIM AI Gateway" "Documented alternative to the self-hosted gateway, kept as a placement option. Not deployed." "Azure API Management" "documented"

        apim -> foundry.foundryInstance "Would front hosted model deployments, if the gateway moved to Azure" "HTTPS/JSON, managed identity" "documented"

        cae.gatewayApp.otel -> appInsights "Ships logs, traces and audit records to" "OTLP over HTTPS, Application Insights connection string from Key Vault"
        cae.gatewayApp.otel -> prometheus "Writes metrics to" "Prometheus remote write, managed identity"
        cae.gatewayApp.gw -> cae.postgres "Stores virtual keys, teams and spend logs in" "PostgreSQL over TLS, managed identity"
        cae.meterJob.meter -> cae.postgres "Reads LiteLLM spend logs from" "PostgreSQL over TLS, managed identity"
        cae.meterJob.meter -> prometheus "Writes attributed cost metrics to" "Prometheus remote write, managed identity"
        cae.evidenceJob.evidence -> appInsights "Collects gateway audit records from" "HTTPS/KQL, managed identity"
        cae.grafanaApp.grafana -> appInsights "Queries logs and traces from" "HTTPS/KQL, managed identity"
        cae.grafanaApp.grafana -> prometheus "Queries metrics from" "HTTPS/PromQL, managed identity"
    }

    // ADR-0005: no longer the lab tier, so nothing here is a live instance.
    // The exit target is modelled as an infrastructure node rather than as a
    // containerInstance of the gateway: Structurizr replicates a container's
    // relationships onto every instance of it, so a second gateway instance
    // drew an idle cluster calling the policy engine and the model runtime in
    // Azure. An infrastructure node keeps the node non-empty for `inspect`
    // without asserting traffic that does not exist.
    onprem = deploymentNode "On-prem Kubernetes" "Documented exit environment (ADR-0005); not deployed. The lab tier moved to Azure Container Apps." "Kubernetes" "documented" {

        exitTarget = infrastructureNode "panoptes namespace (manifests in iac/)" "Where the gateway, the self-hosted model and the observability stack would run on exit. The same images also run from the Compose file in gateway/ on any Docker host. Documented, never applied." "Kubernetes manifests" "documented"
    }

    // Documented, like the APIM edge above: the shape of the exit, not traffic.
    azure.cae.gatewayApp.gw -> onprem.exitTarget "Would be redeployed here on exit from Azure, from the same image" "Compose file in gateway/ or the manifests in iac/" "documented"

    deploymentNode "External providers" "Outside Northgate. Reached from the gateway only, over the internet." "Provider APIs" {
        softwareSystemInstance anthropicApi
        softwareSystemInstance openaiApi
    }
}
