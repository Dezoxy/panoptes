// This repository's styles. The shared meanings (people, systems, external,
// shapes, security markings, arrows) and the approved palette come from
// styles-shared.dsl, copied unchanged from architecture-base. This file only
// maps this system's layers and groups onto palette families, plus local extras.
// Tag order matters on an element: layer tag first, marking last.

styles {
    !include styles-shared.dsl

    // Seven layers, five palette families. styles-shared.dsl allows five, and
    // reserves grey for anything outside the system. The two layers that hold
    // no Panoptes container — the providers and the Copilot estate — are tagged
    // so they can be filtered, but keep the reserved external grey rather than
    // taking a sixth and seventh colour.
    //
    //   Gateway    purple   the way in
    //   Controls   magenta  what decides
    //   Telemetry  teal     what records
    //   Lifecycle  green    what governs
    //   Surfaces   slate    what a consumer reads
    //   Providers  grey     reserved: outside the system
    //   Copilot    grey     reserved: administered, not built

    element "Layer Gateway" {
        background ${PURPLE_FILL}
        stroke ${PURPLE_STROKE}
    }
    relationship "Layer Gateway" {
        color ${PURPLE_STROKE}
    }
    element "Layer Controls" {
        background ${MAGENTA_FILL}
        stroke ${MAGENTA_STROKE}
    }
    relationship "Layer Controls" {
        color ${MAGENTA_STROKE}
    }
    element "Layer Telemetry" {
        background ${TEAL_FILL}
        stroke ${TEAL_STROKE}
    }
    relationship "Layer Telemetry" {
        color ${TEAL_STROKE}
    }
    element "Layer Lifecycle" {
        background ${GREEN_FILL}
        stroke ${GREEN_STROKE}
    }
    relationship "Layer Lifecycle" {
        color ${GREEN_STROKE}
    }
    element "Layer Surfaces" {
        background ${SLATE_FILL}
        stroke ${SLATE_STROKE}
    }
    relationship "Layer Surfaces" {
        color ${SLATE_STROKE}
    }

    // Groups are the layers; their tint follows the layer they hold.
    element "Group:Model gateway" {
        color ${PURPLE_LABEL}
        stroke ${PURPLE_STROKE}
        background ${PURPLE_FRAME}
    }
    element "Group:Controls plane" {
        color ${MAGENTA_LABEL}
        stroke ${MAGENTA_STROKE}
        background ${MAGENTA_FRAME}
    }
    element "Group:Telemetry and FinOps" {
        color ${TEAL_LABEL}
        stroke ${TEAL_STROKE}
        background ${TEAL_FRAME}
    }
    element "Group:Lifecycle" {
        color ${GREEN_LABEL}
        stroke ${GREEN_STROKE}
        background ${GREEN_FRAME}
    }
    element "Group:Consumer surfaces" {
        color ${SLATE_LABEL}
        stroke ${SLATE_STROKE}
        background ${SLATE_FRAME}
    }

    // Local extras.
    //
    // Documented, not running: a design that has been written down and, where
    // it has automation, exercised in dry-run. A dashed border on a deployment
    // node says the same thing the README's status legend says in words.
    element "documented" {
        border dashed
        strokeWidth 3
        color ${EXTERNAL_GREY}
        stroke ${EXTERNAL_GREY}
        opacity 60
    }
    element "Staff" {
        background #ede9fe
    }
    element "Vault" {
        shape Folder
    }
}
