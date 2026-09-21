// Every relationship in the model, in call order. Included after containers.dsl
// so all identifiers exist.
//
// Each relationship names the protocol and, where it crosses a boundary, the
// identity or credential the call carries. A relationship carries the layer tag
// of its source, so the arrow takes the source's colour (see styles-shared.dsl).

// ── Authentication ──────────────────────────────────────────────────────────
engineer -> entraId "Signs in with" "OIDC, workforce tenant" "Person"
businessUser -> entraId "Signs in with" "OIDC, workforce tenant" "Person"
platformOperator -> entraId "Signs in with" "OIDC, workforce tenant, phishing-resistant MFA" "Person"
securityReviewer -> entraId "Signs in with" "OIDC, workforce tenant" "Person"
finopsAnalyst -> entraId "Signs in with" "OIDC, workforce tenant" "Person"

// ── Consumers reaching the platform ─────────────────────────────────────────
engineer -> panoptes.gateway "Sends chat, completion and embedding requests to" "HTTPS/JSON, Entra ID bearer token" "Person"
engineer -> panoptes.portal "Requests access and reads spend against budget in" "HTTPS, OIDC" "Person"
engineer -> panoptes.docsSite "Reads integration guidance on" "HTTPS" "Person"
engineer -> githubCopilot "Uses" "IDE extension, tenant seat" "Person"
businessUser -> panoptes.portal "Requests assistant access through" "HTTPS, OIDC" "Person"
businessUser -> m365Copilot "Uses" "HTTPS, tenant seat" "Person"
businessUser -> copilotStudio "Uses assistants published in" "HTTPS, tenant seat" "Person"

// ── Operating the platform ──────────────────────────────────────────────────
platformOperator -> panoptes.cli "Onboards workloads, sets budgets and collects evidence with" "Command line" "Person"
platformOperator -> zeroTrustProxy "Reaches every admin surface through" "HTTPS, device posture and phishing-resistant MFA" "Person"
securityReviewer -> panoptes.policies "Reviews classification and entitlement rules in" "Pull request" "Person"
securityReviewer -> panoptes.evidence "Reads collected control evidence from" "HTTPS, OIDC" "Person"
finopsAnalyst -> panoptes.grafana "Reviews spend, attribution and budget breaches in" "HTTPS, OIDC" "Person"

// There is no network perimeter: admin access is brokered, never routed.
zeroTrustProxy -> panoptes.gateway "Brokers administrator access to" "HTTPS, device posture and MFA"
zeroTrustProxy -> panoptes.policies "Brokers administrator access to" "HTTPS, device posture and MFA"
zeroTrustProxy -> panoptes.grafana "Brokers administrator access to" "HTTPS, device posture and MFA"

// ── Gateway ─────────────────────────────────────────────────────────────────
panoptes.gateway -> entraId "Validates bearer tokens against" "OIDC/JWKS" "Layer Gateway"
panoptes.gateway -> panoptes.policies "Checks entitlement and the data class to provider mapping with" "HTTP/JSON, in-cluster" "Layer Gateway"
panoptes.gateway -> panoptes.configStore "Loads routing, fallback, quota and rate-limit configuration from" "Kubernetes ConfigMap, rendered from Git" "Layer Gateway"
panoptes.gateway -> panoptes.secretStore "Reads provider API keys from" "HTTPS, workload identity federation" "Layer Gateway"
panoptes.gateway -> panoptes.otel "Emits traces, metrics and the per-call audit record to" "OTLP/gRPC, in-cluster" "Layer Gateway"

panoptes.gateway -> aiFoundry "Calls hosted model deployments on" "HTTPS/JSON, key from the secret store" "Layer Gateway"
panoptes.gateway -> anthropicApi "Calls models on" "HTTPS/JSON, key from the secret store" "Layer Gateway"
panoptes.gateway -> openaiApi "Calls models on" "HTTPS/JSON, key from the secret store" "Layer Gateway"
panoptes.gateway -> selfHostedRuntime "Calls models on" "HTTPS/JSON, in-cluster; no prompt leaves the estate" "Layer Gateway"

// ── Controls plane ──────────────────────────────────────────────────────────
panoptes.policies -> panoptes.entitlements "Reads consumer group membership from" "HTTPS, Microsoft Graph, workload identity" "Layer Controls"
panoptes.entitlements -> entraId "Is held as security groups in" "Microsoft Graph" "Layer Controls"
panoptes.evidence -> panoptes.policies "Collects policy decisions and rule versions from" "HTTP/JSON, in-cluster" "Layer Controls"
panoptes.evidence -> panoptes.loki "Collects gateway audit records from" "HTTP/JSON, in-cluster" "Layer Controls"
panoptes.evidence -> panoptes.register "Collects onboarding and review records from" "Git" "Layer Controls"

// ── Telemetry and FinOps ────────────────────────────────────────────────────
panoptes.otel -> panoptes.loki "Forwards logs and audit records to" "OTLP, in-cluster" "Layer Telemetry"
panoptes.otel -> panoptes.tempo "Forwards traces to" "OTLP, in-cluster" "Layer Telemetry"
panoptes.otel -> panoptes.grafana "Exports platform metrics to" "Prometheus remote write, in-cluster" "Layer Telemetry"
panoptes.otel -> panoptes.meter "Forwards token and request usage events to" "OTLP, in-cluster" "Layer Telemetry"
panoptes.meter -> panoptes.grafana "Writes cost attributed to consumer, model and workload to" "HTTP/JSON, in-cluster" "Layer Telemetry"
panoptes.grafana -> panoptes.loki "Queries logs from" "HTTP/JSON, in-cluster" "Layer Telemetry"
panoptes.grafana -> panoptes.tempo "Queries traces from" "HTTP/JSON, in-cluster" "Layer Telemetry"

// ── Lifecycle ───────────────────────────────────────────────────────────────
panoptes.cli -> panoptes.register "Writes intake, risk tier and lifecycle stage records to" "Git" "Layer Lifecycle"
panoptes.cli -> panoptes.evidence "Reads collected control evidence from" "HTTP/JSON, OIDC" "Layer Lifecycle"
panoptes.cli -> panoptes.configStore "Proposes quota and routing changes in" "Git pull request" "Layer Lifecycle"
panoptes.cli -> panoptes.grafana "Sets consumer budgets and alert thresholds in" "HTTP/JSON, service account token" "Layer Lifecycle"
panoptes.cli -> msGraph "Would apply Copilot estate changes through" "Microsoft Graph, dry-run only: the call is printed, not made" "Layer Lifecycle"

// ── Consumer surfaces ───────────────────────────────────────────────────────
panoptes.portal -> entraId "Authenticates consumers with" "OIDC" "Layer Surfaces"
panoptes.portal -> panoptes.register "Reads onboarding status and risk tier from" "Git" "Layer Surfaces"
panoptes.portal -> panoptes.grafana "Embeds spend and quota panels from" "HTTPS, service account token" "Layer Surfaces"
panoptes.portal -> panoptes.docsSite "Sends consumers to integration guidance on" "HTTPS" "Layer Surfaces"

// ── Copilot estate (administered, not built) ────────────────────────────────
m365Copilot -> msGraph "Is configured and reported on through" "Microsoft Graph"
githubCopilot -> msGraph "Draws seat identity from the tenant through" "Microsoft Graph"
copilotStudio -> msGraph "Is configured and reported on through" "Microsoft Graph"
