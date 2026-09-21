// Software systems outside Panoptes. The system in scope is defined in
// containers.dsl.
//
// Tag meanings come from styles-shared.dsl: "Existing System" is owned inside
// Northgate, "External" is outside it. The layer tags group these systems for
// the reader; the providers and the Copilot estate deliberately keep the
// reserved external grey rather than a layer colour (see styles.dsl).

aiFoundry = softwareSystem "Azure AI Foundry" "Hosts model deployments in the Northgate Azure subscription. Reached only through the gateway." "Existing System,Layer Providers"
anthropicApi = softwareSystem "Anthropic API" "Frontier models under a commercial agreement. Reached only through the gateway." "External,Layer Providers"
openaiApi = softwareSystem "OpenAI API" "Frontier models under a commercial agreement. Reached only through the gateway." "External,Layer Providers"
selfHostedRuntime = softwareSystem "Self-hosted model runtime" "Open-weight models served on the on-prem cluster, for workloads whose data class may not leave the estate." "Existing System,Layer Providers"

entraId = softwareSystem "Microsoft Entra ID" "Issues tokens for people and workloads, and holds the security groups that carry entitlements." "Existing System"
msGraph = softwareSystem "Microsoft Graph" "Administrative API for the Microsoft 365 tenant. Panoptes calls it in dry-run mode only; there is no tenant to change." "Existing System,Layer Copilot"
zeroTrustProxy = softwareSystem "Zero-trust access proxy" "Brokers administrator access to admin surfaces on device posture and MFA. There is no network perimeter to be inside of." "Existing System"

m365Copilot = softwareSystem "Microsoft 365 Copilot" "Administered, not built. Tenant configuration, rollout and reporting are platform work." "Existing System,Layer Copilot"
githubCopilot = softwareSystem "GitHub Copilot" "Administered, not built. Seat assignment, policy and telemetry are platform work." "Existing System,Layer Copilot"
copilotStudio = softwareSystem "Copilot Studio" "Administered, not built. Assistants published here are governed by the same entitlement and classification rules." "Existing System,Layer Copilot"
