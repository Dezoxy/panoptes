// Each view answers one question. Every view uses automatic layout; no element
// in this workspace carries hand-placed coordinates.

// The Copilot estate reaches Panoptes only through the tenant admin API, so
// "include *" leaves it out. It is named explicitly: administered surfaces are
// part of the fleet, and a context view that hides them understates the scope.
systemContext panoptes "SystemContext" "Who uses Panoptes, and what does it depend on?" {
    include *
    include m365Copilot githubCopilot copilotStudio
    autoLayout lr
}

// Fifteen containers plus the people and systems that touch them is above the
// ~15 element guideline the base sets. The Copilot estate and Microsoft Graph
// are excluded here: they are administered rather than built, they attach only
// to the CLI, and the SystemContext view already answers where they sit. This
// view will still need splitting once the ADRs settle the controls plane.
container panoptes "Containers" "What are the building blocks of Panoptes, layer by layer?" {
    include *
    exclude m365Copilot githubCopilot copilotStudio msGraph
    autoLayout tb 300 150
}

// One chat completion, end to end. This is the path every consumer takes and
// the only path to a provider.
dynamic panoptes "ChatCompletion" "What happens on one chat completion request?" {
    engineer -> entraId "Requests an access token for the gateway"
    engineer -> panoptes.gateway "Sends the chat completion request with the bearer token"
    panoptes.gateway -> entraId "Validates the token and reads the consumer claim"
    panoptes.gateway -> panoptes.policies "Asks whether this consumer may send this data class to this model"
    panoptes.policies -> panoptes.entitlements "Reads the consumer's group membership"
    panoptes.gateway -> panoptes.secretStore "Reads the API key for the chosen provider"
    panoptes.gateway -> anthropicApi "Forwards the request to the routed provider"
    panoptes.gateway -> panoptes.otel "Emits the trace, the token counts and the audit record"
    panoptes.otel -> panoptes.meter "Forwards the usage event for cost attribution"
    panoptes.meter -> panoptes.grafana "Writes the cost against the consumer's budget"
    autoLayout lr
}

// Three environments in one view, because placement is the decision this view
// exists to show.
deployment panoptes "Platform" "PlatformDeployment" "Where does each part of Panoptes run, and which boundaries does a call cross?" {
    include *
    autoLayout lr
}
