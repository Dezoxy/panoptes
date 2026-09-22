# 0004. Run CI/CD on GitHub Actions, with portable pipelines

## Status

Accepted

## Date

2026-09-21

## Context

The repository lives at `github.com/Dezoxy/panoptes`. CI is already load-bearing: `pre-commit`
gates every commit, the architecture workspace is validated and exported on each change, and
`../iac/` will shortly need `terraform plan` and `terraform apply` against an Azure subscription.

That last part is the reason this needs a record rather than a configuration commit. A pipeline that
can apply Terraform to the Azure landing zone holds the most privileged identity on the platform,
which makes the CI system a security boundary in its own right.

The tension is between the repository's host and the firm's estate. Northgate is Microsoft-centred,
and an enterprise standards document would name Azure DevOps Pipelines. The repository is on GitHub,
so GitHub Actions is the pipeline runner that needs no additional service, account or integration.
The decision is therefore less about which runner is better and more about how much the choice costs
to reverse.

## Decision drivers

- **No second system to operate.** One operator; a CI system that needs its own hosting or its own
  identity integration earns nothing here.
- **The choice must be cheap to reverse.** The firm's estate may standardise on Azure DevOps; that
  should be a translation, not a redesign.
- **No stored cloud credentials.** A pipeline applying Terraform must authenticate without a
  long-lived secret, matching the boundary table in `../docs/architecture/overview/README.md`.
- **The whole toolchain must run.** Terraform, tflint, trivy and checkov are all gates; a runner
  that cannot host them is not a candidate.

## Considered options

1. GitHub Actions, with pipelines kept deliberately portable.
2. Azure DevOps Pipelines.
3. GitLab CI.
4. Jenkins, self-hosted.
5. `pre-commit.ci` alone, with no separate pipeline.

## Decision

CI/CD runs on **GitHub Actions**, because the repository is on GitHub and no other service, account
or integration is needed to make it work. Pipelines are kept deliberately portable: plain shell
steps, container images pinned by digest or exact tag, and no marketplace-only logic where a shell
command does the same job. Marketplace actions are used for checkout, language setup and cloud login
— the places where reimplementation buys nothing — and nowhere else. The test of portability is
concrete: moving to Azure DevOps Pipelines must be a translation of workflow files, not a redesign
of what the pipelines do.

Terraform apply from CI authenticates to Azure through **OIDC workload identity federation**, with
no client secret stored in the repository or in GitHub. That federation is set up in Phase 1,
alongside the landing zone it needs to reach.

## Consequences

### Positive

- CI is where the code is, so a pull request, its checks and its review sit in one place with
  nothing to synchronise.
- Portability is a property of the pipelines rather than a promise: shell steps and pinned images
  are readable and runnable anywhere, including locally when a failure needs reproducing.
- OIDC federation means no Azure credential is stored anywhere, so there is nothing to rotate and
  nothing to leak from repository settings.
- The runner hosts the full Terraform toolchain, so the hooks `pre-commit.ci` skips still run on
  every change.

### Negative and accepted trade-offs

- Action pins by major tag need reviewing on a cadence; an unreviewed pin is a supply-chain
  dependency that updates itself.
- Avoiding marketplace convenience costs verbosity. Some steps are ten lines of shell where an
  action would have been three.
- Hosted runners are outside the firm's estate, so build logs and any artefact they touch leave it.
  Nothing secret may be printed in a workflow.
- The federated identity is privileged enough to change the landing zone, which makes repository and
  environment protection rules a control, not a preference.

## Rejected alternatives

### Option 2 — Azure DevOps Pipelines

- **Why not** — the natural choice for a Microsoft-centred estate, named in many enterprise
  standards, and it sits next to the Azure resources it would deploy. It loses only on hosting: the
  repository is on GitHub, so this means a second service, a second identity surface and a
  repository mirror or a move.
- **Revisit if** — the repository moves to Azure Repos, or the firm mandates Azure DevOps for
  pipelines. The portability rule above exists to make that a workflow-file translation.

### Option 3 — GitLab CI

- **Why not** — a capable runner, but adopting it means moving repository hosting as well, and
  nothing about GitHub hosting is currently a problem worth a migration.
- **Revisit if** — repository hosting moves to GitLab for an unrelated reason. CI would follow the
  repository rather than drive it.

### Option 4 — Jenkins, self-hosted

- **Why not** — it would run on the same single lab node as the gateway, adding a service to patch,
  back up and secure, in exchange for capability the hosted runners already provide.
- **Revisit if** — pipelines need direct access to on-prem resources that no hosted runner can
  reach, and a self-hosted GitHub Actions runner cannot cover the gap either.

### Option 5 — `pre-commit.ci` alone

- **Why not** — it already runs the linting hooks, but it has no Terraform toolchain, which is why
  `../.pre-commit-config.yaml` explicitly skips `terraform_fmt`, `terraform_validate`,
  `terraform_tflint`, `terraform_trivy` and `terraform_checkov` there. Those are the gates that
  matter most on `../iac/`.
- **Revisit if** — never as the only pipeline. It stays alongside GitHub Actions for hook
  autoupdates.

## Risks

- **A pinned action is compromised upstream.** Detectable by dependency review and by the pin-review
  cadence; the blast radius is the federated Azure identity, so permissions stay least-privilege.
- **Portability erodes one convenient action at a time.** Detectable in review: a workflow step that
  cannot be described as a shell command is the signal.
- **The federated identity is over-permissioned.** Detectable by a role-assignment review on the
  subscription and by `checkov` findings on `../iac/`.

## Related

- **Requirements** — `../CONTRIBUTING.md`, `../.pre-commit-config.yaml`, `../iac/`
- **Other ADRs** — [0001](0001-record-architecture-decisions.md),
  [0002](0002-hybrid-topology-and-placement.md), [0003](0003-model-gateway-litellm.md)
