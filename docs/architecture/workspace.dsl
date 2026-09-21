// Entry point for the architecture model. Keep this file at docs/architecture/:
// the !docs path must be this directory or a subdirectory of it.
// Model fragments live in model/ and are pulled in with !include (order matters:
// people and external systems before the containers that reference them, and
// relationships last, once every identifier exists).
//
// ADRs live in adr/ at the repository root, outside this directory, so they are
// not imported with !adrs. docs/architecture/README.md links to them.
workspace "Panoptes" "Architecture model for Panoptes, the shared AI platform for Northgate Asset Management." {

    !identifiers hierarchical

    configuration {
        scope softwaresystem
    }

    // Attached to the workspace, not the software system, so the path resolves
    // unambiguously against this file.
    !docs overview

    properties {
        // Documentation is attached at workspace level (above) and decisions are
        // not imported at all, so the per-system inspections do not apply here.
        "structurizr.inspection.model.softwaresystem.documentation" "ignore"
        "structurizr.inspection.model.softwaresystem.decisions" "ignore"
    }

    model {
        !include model/people.dsl
        !include model/systems.dsl
        !include model/containers.dsl
        !include model/relationships.dsl
        !include model/deployment.dsl
    }

    views {
        !include model/views.dsl
        !include model/styles.dsl
    }

}
