# KubeRocketCI Components

Deep-dive reference for the KubeRocketCI component repositories cloned into this `sources/` directory. Each subdirectory here is an independent git repo. For workspace provisioning (bootstrap, search rules, commands) see the root `../CLAUDE.md`.

## Platform Architecture (TL;DR)

Developer pushes code → Git webhook → Tekton interceptor enriches payload → Tekton pipeline (build/test/SAST/SonarQube) → image pushed to registry → CD Pipeline Operator promotes artifact → Argo CD deploys to cluster. All authentication flows through Keycloak OIDC. All configuration is managed as Kubernetes CRDs.

## Repositories

### Portal & UI

**`krci-portal`** — `TypeScript` · React 19 + tRPC + Fastify monorepo (pnpm workspaces).
The primary web UI for the platform. `apps/client/` is the React SPA, `apps/server/` is the Fastify/tRPC backend, `packages/trpc/` holds tRPC routers and Kubernetes API clients, `packages/shared/` holds shared types and Kubernetes resource interfaces. Talks to the Kubernetes API directly — reads and writes all KRCI CRDs.

**`cli`** — `Go` · Cobra CLI, talks to krci-portal tRPC/REST API (no direct Kubernetes access).
The `krci` terminal tool for managing codebases, pipeline runs, deployments, and environments. Designed for both human use and AI-agent workflows (all data commands emit structured JSON). Entry: `cmd/`, commands under `pkg/cmd/<group>/<verb>/`, portal client in `internal/portal/`.

---

### CI — Tekton

**`edp-tekton`** — `Go` + `Helm/YAML` · Tekton interceptor binary + pipelines-library Helm chart.
Two components: (1) a `ClusterInterceptor` HTTP server (`cmd/interceptor/`) that enriches VCS webhook payloads (GitHub, GitLab, Gerrit, Bitbucket) with `Codebase`/`CodebaseBranch` metadata; (2) `charts/pipelines-library/` — the full library of Tekton Tasks, Pipelines, TriggerBindings, TriggerTemplates, and EventListeners covering 10+ languages across all four VCS providers. This is the heart of KRCI CI.

**`tekton-custom-task`** — `Go` · kubebuilder operator.
Extends Tekton with custom task types. Defines the `ApprovalTask` CRD (`api/v1alpha1/`) — a human-approval gate that pauses a `PipelineRun` until explicitly approved or rejected. Controller in `internal/`, Helm chart in `deploy-templates/`.

**`tekton-pipeline-queue`** — `Go` · kubebuilder v4 operator.
Queues Tekton PipelineRuns instead of letting them all start at once. Producers create runs paused (`spec.status: PipelineRunPending`); a `PipelineRunQueue` CR (`edp.epam.com/v1alpha1`) selects them by label selector, groups them into *lanes* by `queueKey` label values (e.g. codebase + branch), and admits them FIFO per lane up to `concurrency`, with `Queue`/`ReplaceQueued`/`CancelInProgress` strategies. Stateless by design — every reconcile recomputes from the live PipelineRun set. Controller in `internal/controller/`, types in `api/v1alpha1/`, Helm chart in `deploy-templates/`. Read its `AGENTS.md` before editing — several outputs are generated and CI-enforced (`make validate-docs`).

**`krci-cache`** — `Go` · Echo HTTP server.
A lightweight artifact cache for Tekton pipelines. Accepts uploads (with optional tar.gz extraction) and serves cached files. Optimized for memory-constrained pods (targets 512 MB). Entry: `main.go`, logic in `uploader/`.

---

### CD — Operators

**`edp-codebase-operator`** — `Go` · kubebuilder operator.
Reconciles codebase entities: provisions Git repositories, manages branches, git servers, Jira integration, and image streams. Defines the core source-of-truth CRDs consumed by almost every other component.
CRDs (`v2.edp.epam.com/v1`): `Codebase`, `CodebaseBranch`, `GitServer`, `JiraServer`, `JiraIssueMetadata`, `CDStageDeploy`, `CodebaseImageStream`, `QuickLink`. Entry: `cmd/main.go`, controllers in `controllers/`, types in `api/v1/`.

**`edp-cd-pipeline-operator`** — `Go` · kubebuilder operator.
Reconciles continuous delivery pipeline entities and handles promotion between environments on Kubernetes and OpenShift.
CRDs (`v2.edp.epam.com/v1`): `CDPipeline`, `Stage`. Entry: `cmd/main.go`, types in `api/v1/`, controllers in `internal/`.

---

### Platform Operators

**`edp-keycloak-operator`** — `Go` · kubebuilder operator with admission webhooks.
Configures an existing Keycloak instance declaratively — manages realms, clients, users, groups, roles, identity providers, auth flows, and client scopes as CRDs. Keycloak REST client auto-generated via oapi-codegen in `pkg/client/keycloakapi/`.
CRDs (`v1`): `Keycloak`, `KeycloakRealm`, `KeycloakClient`, `KeycloakClientScope`, `KeycloakRealmGroup`, `KeycloakRealmUser`, `KeycloakRealmRole`, `KeycloakRealmRoleBatch`, `KeycloakRealmIdentityProvider`, `KeycloakAuthFlow`, `KeycloakComponent`. Cluster-scoped (`v1alpha1`): `ClusterKeycloak`, `ClusterKeycloakRealm`, `KeycloakOrganization`.

**`edp-nexus-operator`** — `Go` · kubebuilder operator.
Configures an existing Nexus Repository Manager — manages repositories, blob stores, cleanup policies, roles, users, and scripts as CRDs.
CRDs (`edp.epam.com/v1alpha1`): `Nexus`, `NexusRepository`, `NexusBlobStore`, `NexusCleanupPolicy`, `NexusRole`, `NexusUser`, `NexusScript`.

**`edp-sonar-operator`** — `Go` · kubebuilder operator.
Configures an existing SonarQube instance — manages quality gates, quality profiles, projects, users, groups, and permission templates as CRDs. Quality gates defined here are the blocking gates enforced in every CI pipeline.
CRDs (`edp.epam.com/v1alpha1`): `Sonar`, `SonarProject`, `SonarQualityGate`, `SonarQualityProfile`, `SonarUser`, `SonarGroup`, `SonarPermissionTemplate`.

---

### Supporting Services

**`gitfusion`** — `Go` · Echo HTTP server, OpenAPI-driven.
A unified Git provider adapter that normalises GitHub, GitLab, and Bitbucket APIs behind a single REST interface. Used by the portal for repository/branch/PR discovery. API spec drives server and client code via oapi-codegen. Entry: `cmd/`, provider implementations in `pkg/services/`, Helm chart in `deploy-templates/`.

---

### Platform Configuration & Docs

**`edp-cluster-add-ons`** — `Helm/YAML` · Argo CD App-of-Apps, no compiled code.
A curated catalog of pre-configured Kubernetes add-on Helm charts (Argo CD, cert-manager, external-secrets, Atlantis, etc.) for bootstrapping a KRCI cluster via GitOps. `clusters/core/apps/` is the umbrella App-of-Apps chart; `clusters/core/addons/` holds individual add-on charts; `clusters/prod/` holds production overrides.

**`edp-install`** — `Helm` · Umbrella installation chart, no compiled code.
The top-level meta Helm chart for installing the entire KubeRocketCI platform. References all component charts as sub-chart dependencies. Use as the canonical entry point for platform installation and values documentation.

**`krci-docs`** — `TypeScript` · Docusaurus v3 static site.
The official documentation website (docs.kuberocketci.io). `docs/` holds current Markdown content, `versioned_docs/` holds per-release snapshots. The authoritative reference for operator guides, user guides, API references, and architecture documentation.

**`claude-code-telemetry`** — `Helm/YAML` + `Docker Compose` · Self-hosted OpenTelemetry back end for Claude Code usage.
Ingests the OTel metrics/events Claude Code emits and attributes them to business dimensions (`organization`, `project`, `jira.epic`, `jira.story`) without capturing prompts or file contents. Pipeline: OTel Collector → Prometheus (metrics) + Loki (events) → Grafana (dashboards), packaged for both a laptop (`local/` Docker Compose testbed) and a cluster (`deploy-templates/` Helm chart). Not part of the KRCI CI/CD data path — an observability tool for teams operating Claude Code itself.

---

## Key CRD Group Summary

| Group | Repo | Core Types |
|---|---|---|
| `v2.edp.epam.com` | edp-codebase-operator | Codebase, CodebaseBranch, GitServer, CodebaseImageStream |
| `v2.edp.epam.com` | edp-cd-pipeline-operator | CDPipeline, Stage |
| `v1.edp.epam.com` | edp-keycloak-operator | Keycloak, KeycloakRealm, KeycloakClient, … |
| `edp.epam.com` | edp-nexus-operator | Nexus, NexusRepository, … |
| `edp.epam.com` | edp-sonar-operator | Sonar, SonarQualityGate, … |
| `edp.epam.com` | tekton-custom-task | ApprovalTask |
| `edp.epam.com` | tekton-pipeline-queue | PipelineRunQueue |

## Cross-Repo Data Flow

```
Git push
  → edp-tekton (ClusterInterceptor enriches with Codebase/CodebaseBranch)
  → tekton-pipeline-queue (admits pending PipelineRuns FIFO per lane)
  → Tekton Pipeline (clone → build → test → SAST → SonarQube gate)
  → image pushed to Nexus/registry
  → edp-codebase-operator updates CodebaseBranch status
  → edp-cd-pipeline-operator triggers CDPipeline promotion
  → Argo CD deploys (via edp-cluster-add-ons configuration)
  → krci-portal / cli expose status to user
```

## Agent Tips

- To understand a bug in the portal, start at `krci-portal/packages/trpc/` — that's where Kubernetes API calls are made.
- To trace a CI pipeline failure, look at `edp-tekton/charts/pipelines-library/templates/tasks/` for task definitions.
- To understand a CRD schema, check `api/v1/` or `api/v1alpha1/` in the relevant operator repo.
- All operators follow the same structure: `cmd/main.go` → manager setup, `api/<version>/` → types, `internal/controller/` or `controllers/` → reconcilers.
- `edp-cluster-add-ons` is the single source of truth for which third-party tools are deployed and how they are configured.
