// Where the containers run. Placement is hybrid, so the three environments the
// platform spans — Azure, the on-prem cluster and the provider APIs — are
// modelled as top-level deployment nodes of one environment rather than as
// separate deploymentEnvironment blocks. One view then shows the whole estate
// and the boundaries it crosses, which is the question the reader has.
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

    deploymentNode "Azure subscription (West Europe)" "sub-panoptes-prod. EU region only; no model data leaves the EU." "Microsoft Azure" "Azure" {

        deploymentNode "Identity plane" "Northgate workforce tenant. Not a per-subscription resource; drawn here because it is the Azure-side identity boundary." "Microsoft Entra ID" {
            softwareSystemInstance entraId
            containerInstance panoptes.entitlements
        }

        foundry = deploymentNode "Azure AI Foundry" "Hosted model deployments, West Europe only." "Azure AI Foundry" {
            softwareSystemInstance aiFoundry
        }

        deploymentNode "kv-panoptes-weu" "RBAC mode, private endpoint, purge protection on." "Azure Key Vault" {
            containerInstance panoptes.secretStore
        }

        // Documented, not running. The dashed border is the whole point: it says
        // the design was written down, not that the control is in force.
        apim = infrastructureNode "APIM AI Gateway" "Documented alternative to the self-hosted gateway, kept as a placement option. Not deployed." "Azure API Management" "documented"

        apim -> foundry "Would front hosted model deployments, if the gateway moved to Azure" "HTTPS/JSON, managed identity" "documented"
    }

    deploymentNode "On-prem Kubernetes" "The estate Panoptes runs on. Admin surfaces are reachable only through the zero-trust proxy." "Kubernetes" {

        deploymentNode "panoptes" "Namespace" "Kubernetes namespace" {

            deploymentNode "panoptes-gateway" "Horizontally scaled; a restart must not drop an in-flight call." "Kubernetes Deployment" "" 2 {
                containerInstance panoptes.gateway
                containerInstance panoptes.configStore
            }

            deploymentNode "panoptes-policies" "Sidecar-free; the gateway calls it over the cluster network." "Kubernetes Deployment" "" 2 {
                containerInstance panoptes.policies
            }

            deploymentNode "panoptes-meter" "Batch and streaming cost attribution." "Kubernetes Deployment" {
                containerInstance panoptes.meter
                containerInstance panoptes.evidence
            }

            deploymentNode "observability" "The telemetry stack, running beside what it observes." "Kubernetes Deployment" {
                containerInstance panoptes.otel
                containerInstance panoptes.loki
                containerInstance panoptes.tempo
                containerInstance panoptes.grafana
            }

            deploymentNode "lifecycle" "Records and consumer-facing surfaces." "Kubernetes Deployment" {
                containerInstance panoptes.register
                containerInstance panoptes.portal
                containerInstance panoptes.docsSite
            }

            deploymentNode "model-runtime" "GPU node pool. Serves the data classes that may not leave the estate." "Kubernetes Deployment" {
                softwareSystemInstance selfHostedRuntime
            }
        }
    }

    deploymentNode "External providers" "Outside Northgate. Reached from the gateway only, over the internet." "Provider APIs" {
        softwareSystemInstance anthropicApi
        softwareSystemInstance openaiApi
    }
}
