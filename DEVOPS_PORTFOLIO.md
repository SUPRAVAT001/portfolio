# DevOps Engineering Portfolio

**Supravat Dash** · DevOps Engineer · Platform Engineer · SRE
GitHub: [SUPRAVAT001](https://github.com/SUPRAVAT001) · GitLab: [supravatdash7399](https://gitlab.com/supravatdash7399)

---

## Professional Summary

DevOps Engineer with hands-on expertise in Kubernetes platform engineering, GitOps continuous delivery, CI/CD automation, and cloud-native observability. Demonstrated ability to design, build, and operate end-to-end delivery pipelines from application code to production-grade Kubernetes workloads. Proficient in implementing security-conscious container architectures, GitOps reconciliation workflows, and infrastructure monitoring stacks.

The two projects below represent independently designed and implemented platforms — not tutorials or guided exercises. Both run on a self-managed Kubernetes environment (Minikube on WSL2) and demonstrate real engineering decisions, real troubleshooting, and verifiable outcomes.

---

## Project Overview

| # | Project | Purpose | Key Technologies | Repository |
|---|---------|---------|-----------------|------------|
| 1 | **Kubernetes Observability Platform** (`kube-obs`) | Full-stack metrics collection, alerting, and visualization for Kubernetes workloads | Prometheus, Grafana, Alertmanager, kube-state-metrics, Node Exporter, FastAPI, Helm, NGINX Ingress, TLS | [github.com/SUPRAVAT001/kube-obs](https://github.com/SUPRAVAT001/kube-obs) |
| 2 | **GitOps CI/CD Delivery Platform** (`git-argo`) | End-to-end automated delivery: GitLab CI → Registry → GitHub → Argo CD → Kubernetes | GitLab CI/CD, Argo CD, GitHub, Docker, Helm, FastAPI, Pytest, Kubernetes | [github.com/SUPRAVAT001/git-argo](https://github.com/SUPRAVAT001/git-argo) · [gitlab.com/supravatdash7399/git-argo](https://gitlab.com/supravatdash7399/git-argo) |
| 3 | **Autonomous AI SRE Control Plane** (`devops-jarvis`) | Governed bounded autonomy control plane with deterministic safety gates & progressive delivery | Python 3.12, FastAPI, PostgreSQL 16, OPA/Rego, SQLAlchemy, Docker Compose, Kubernetes, Prometheus | Active Development · 1,419 Passing Tests |

---

## Project 1: Kubernetes Observability Platform (`kube-obs`)

### Problem Statement

Operating a Kubernetes cluster without visibility is an unacceptable operational risk. When workloads fail or degrade, engineers need to know immediately — before users notice. This project implements a full observability stack on Kubernetes that collects infrastructure and application metrics, provides alert routing, and delivers visualized dashboards.

### Architecture

```
Kubernetes Cluster (Minikube)
│
├── Prometheus              — Metrics scraping and TSDB storage
│   └── Scrapes: Node Exporter, kube-state-metrics, FastAPI /metrics
│
├── Alertmanager           — Alert routing and notification dispatch
│   └── Rules: Pod crash-loop, high memory, endpoint unavailability
│
├── Grafana                — Dashboard visualization
│   └── Dashboards: Kubernetes node, pod resource, application telemetry
│
├── kube-state-metrics     — Kubernetes object state → Prometheus metrics
├── Node Exporter          — Host-level OS and hardware metrics
│
├── FastAPI Demo App       — Instrumented workload with /metrics endpoint
│
└── NGINX Ingress          — TLS-terminated external access
    └── TLS: Self-signed certificate via cert-manager or manual secret
```

### Implementation Highlights

- **Prometheus scraping** configured with custom `scrape_configs` targeting both infrastructure components (Node Exporter, kube-state-metrics) and application pods via annotations (`prometheus.io/scrape: "true"`).
- **Alertmanager** configured with alerting rules covering crash-loop backoff detection, pod unavailability, and high memory consumption; alert receivers configured for notification dispatch.
- **Grafana dashboards** built to visualize Kubernetes resource utilization, pod lifecycle events, and custom application metrics.
- **TLS termination** via NGINX Ingress with certificate management, enabling HTTPS access to Grafana and application endpoints.
- **Helm-based deployment** allowing reproducible installation and configuration of all components via `values.yaml` overrides.
- **Controlled failure demonstration**: Application pods deliberately terminated to trigger alert pipelines and validate end-to-end observability (crash loop → Prometheus alert → Alertmanager notification → Grafana visualization).
- **Webhook alert integration**: Alertmanager configured to dispatch alerts to an external webhook receiver, demonstrating notification pipeline correctness.

### Technologies Implemented

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Metrics collection | Prometheus | Scrape, store, and query time-series metrics |
| Alerting | Alertmanager | Route and dispatch alerts from Prometheus rules |
| Visualization | Grafana | Dashboard rendering and metric exploration |
| Cluster state metrics | kube-state-metrics | Deployment, pod, and node state as Prometheus metrics |
| Host metrics | Node Exporter | CPU, memory, disk, and network at OS level |
| Demo workload | FastAPI (Python) | Instrumented application exposing `/metrics` |
| Packaging | Helm | Reproducible deployment with configurable values |
| Ingress | NGINX Ingress Controller | HTTP/HTTPS routing with TLS termination |
| Cluster | Kubernetes (Minikube) | Local single-node container orchestration |

### Operational Evidence

- Full stack deployed and operational on Minikube (verified during `git-argo` Phase 3–5 — all 8 `kube-obs` pods confirmed running alongside Argo CD and `gitops-demo` workloads).
- Controlled failure simulations executed: pod termination triggers Prometheus alert within configured evaluation period.
- Stack ran concurrently with Argo CD and `gitops-demo` deployment within a constrained 4.3 GiB WSL2 node — confirming resource-efficient Helm configuration.

---

## Project 2: GitOps CI/CD Delivery Platform (`git-argo`)

### Problem Statement

Manual Kubernetes deployments — applying YAML directly or running `kubectl` commands — are error-prone, non-auditable, and difficult to roll back. This project implements a production-pattern delivery workflow where Git is the single source of truth, CI/CD handles validation and image publishing, and Kubernetes state is continuously reconciled automatically.

### Architecture

```
Developer Push (GitLab Source Repository)
        │
        ▼
GitLab CI/CD Pipeline (5 Stages)
  Stage 1: validate  → Python py_compile + YAML lint + helm lint
  Stage 2: test      → Pytest suite (6 test cases) + JUnit XML report
  Stage 3: build     → docker:27 DinD multi-stage build, tagged ${CI_COMMIT_SHORT_SHA}
  Stage 4: publish   → Push to registry.gitlab.com/supravatdash7399/git-argo:<sha>
  Stage 5: update-gitops → Clone GitHub, sed image tag in values.yaml, git push [skip ci]
        │
        ▼
GitHub Repository (Source of Truth)
  helm/gitops-demo/values.yaml
  image.repository: registry.gitlab.com/supravatdash7399/git-argo
  image.tag: <commit-sha>
        │
        ▼
Argo CD (Kubernetes Controller)
  Polls GitHub every 3 minutes (or webhook)
  Detects values.yaml change
  Reconciles desired state → live cluster state
  selfHeal: true  →  automatic drift correction
        │
        ▼
Kubernetes (Minikube, namespace: gitops-demo)
  Deployment: gitops-demo (1 replica)
  Image: registry.gitlab.com/supravatdash7399/git-argo:<sha>
  Security: runAsUser 10001, capabilities drop ALL, seccompProfile RuntimeDefault
  Probes: liveness /health, readiness /health
  Resources: requests 50m/64Mi, limits 200m/128Mi
```

### Key Engineering Decisions

| Decision | Rationale |
|----------|-----------|
| GitLab for CI/CD, GitHub for GitOps | Separation of concerns — CI/CD concerns (secrets, runners, pipelines) vs. deployment configuration (auditable Git history, Argo CD integration) |
| Immutable commit SHA tags (not `latest`) | Deterministic, reproducible deployments; instant rollback by reverting a single file |
| `selfHeal: true` in Argo CD | Cluster state continuously enforced from Git — eliminates configuration drift silently accumulating |
| Non-root container (UID 10001, `drop: [ALL]`) | Principle of least privilege; prevents container breakout privilege escalation |
| `GITOPS_GITHUB_TOKEN` masked and protected | CI secrets never exposed in pipeline logs or non-protected branches |
| `[skip ci]` on GitOps promotion commit | Prevents infinite loop: CI bot commit does not re-trigger the pipeline |
| `entrypoint: [""]` on `alpine/git:2.45.2` | Required to override the image's default Git entrypoint and allow arbitrary shell commands in GitLab CI — discovered and fixed through direct debugging |

### Real Troubleshooting: Pipeline Failures Diagnosed and Fixed

Three distinct pipeline failures were encountered, diagnosed, and resolved during implementation:

**Failure 1 — YAML Colon Parser Error (Pipeline #3044939xxx)**
- **Symptom**: Pipeline YAML refused to parse; GitLab flagged a mapping key collision.
- **Root cause**: `echo "==>...: ${TAG}"` — the colon after the label text caused the GitLab YAML parser to interpret the string as a dictionary mapping key rather than a string literal.
- **Fix**: Wrapped all echo strings containing colons in single quotes (`'echo "==>...: ${TAG}"'`). Committed as `1fda3f5`.

**Failure 2 — alpine/git Entrypoint Conflict (Pipeline #3045017523)**
- **Symptom**: Stage 5 failed with `git: 'sh' is not a git command`.
- **Root cause**: The `alpine/git:2.45.2` Docker image sets its `ENTRYPOINT` to `/usr/bin/git`, so GitLab's injected shell (`sh -c ...`) was passed as an argument to `git`, not the shell.
- **Fix**: Added `entrypoint: [""]` to override the image entrypoint, restoring standard shell execution. Committed as `9dbdf50`.

**Failure 3 — Wrong Image Repository in values.yaml (pre-deploy detection)**
- **Symptom**: Would have caused `ImagePullBackOff` — Stage 5 only updated `image.tag` but left `image.repository: gitops-demo` pointing to DockerHub.
- **Fix**: Updated Stage 5 `sed` command to also replace `repository:` field with `${CI_REGISTRY_IMAGE}` before updating `tag:`. Committed as `2376a62`.

### Verified Execution Evidence

| Evidence | Detail |
|----------|--------|
| GitLab Pipeline | [#3045047835](https://gitlab.com/supravatdash7399/git-argo/-/pipelines/3045047835) — 5/5 stages PASSED, duration ~3m 7s |
| GitLab Runner | `k8s.saas-linux-small-amd64.runners-manager.gitlab.com` (shared SaaS runner) |
| Published Image | `registry.gitlab.com/supravatdash7399/git-argo:9dbdf50d` |
| GitHub Promotion Commit | `a58cf62` — authored by `GitLab CI/CD Bot <ci-bot@gitlab.com>` |
| Argo CD Reconciliation | Commit `a58cf62` → Synced + Healthy |
| Live Endpoint | `/version` returns `{"version":"9dbdf50d"}`, `/health` returns HTTP 200 |
| Drift Detection | `kubectl scale --replicas=3` → OutOfSync detected → self-healed to 1 replica |
| Declarative Rollback | `git revert a702fba` → Argo CD rolled back v2.0.0 → v1.0.0 with zero downtime |
| Screenshots | 13 PNG screenshots archived in `screenshots/` directory |

---

## Project 3: Autonomous AI SRE Control Plane (`devops-jarvis`)

### Problem Statement

Integrating Large Language Models into infrastructure operations introduces grave operational risks: hallucinations, prompt injection, and stochastic behavior can lead to catastrophic outages if models are given unbounded command execution privileges. `devops-jarvis` solves this by introducing **Governed Bounded Autonomy**: AI agents propose intent and synthesize plans, but are cryptographically and architecturally prevented from directly executing mutations.

### Architecture

```
Natural Language Intent
        │
        ▼
Intent & Context Engine (Stochastic LLM)
  • Extracts user goal & queries Engineering Context Graph
  • Synthesizes structured action plan
        │
        ▼
Deterministic ExecutionController (Mandatory Choke Point)
  • Policy Gate: Open Policy Agent (OPA/Rego) declarative rules
  • Risk Engine: Dynamic blast radius calculation & environment weighting
  • Simulation Gate: Dry-run cluster readback checking state preconditions
  • Approval Gate: Human-in-the-loop authorization for high-risk actions
        │
        ▼
Distributed Concurrency & Lease Engine
  • PostgreSQL 16 row-level locks (SELECT ... FOR UPDATE)
  • Monotonic fencing tokens (prevents zombie worker split-brain mutations)
        │
        ▼
Autonomous Progressive Delivery Engine
  • Multi-stage canary traffic splitting (10% → 25% → 50% → 100%)
  • Live Prometheus telemetry evaluation
  • Epistemic invariants: UNKNOWN != SAFE, STALE != FRESH
        │
        ▼
Kubernetes Cluster & NGINX Ingress (Actuation Target)
```

### Key Capabilities & Verified Status

* **Status**: Milestone 9 Phase 3 Complete & Verified.
* **Deterministic Test Suite**: **1,419 passed**, 3 skipped, 0 failures.
* **Database Migration Head**: PostgreSQL 16 at Alembic revision `c5d6e7f8a9b0 (head)`.
* **Bounded Progressive Delivery**: Evaluates real-time Prometheus error rates and latencies to drive automated canary progression with instant automatic rollbacks on SLO breach.
* **Self-Healing Reconciliation Loops**: Interrupted workflows (e.g., node reboot mid-rollout) are detected and recovered autonomously on startup and periodic background ticks using authoritative cluster readbacks.

---

## Cross-Project Skills Demonstrated

| Skill Domain | Evidence |
|-------------|---------|
| **Kubernetes** | Multi-namespace cluster operation, resource management, security contexts, probes, RBAC |
| **Helm** | Chart authoring (Deployment, Service, ConfigMap, ServiceAccount, Ingress templates), `values.yaml` parameterization |
| **GitOps / Argo CD** | Application CR configuration, automated sync, selfHeal, drift detection verification |
| **CI/CD** | 5-stage GitLab pipeline: lint → test → build → publish → promote |
| **Docker** | Multi-stage builds, non-root user (UID 10001), capability dropping, `.dockerignore` |
| **Observability** | Prometheus scraping, Alertmanager routing, Grafana dashboards, custom `/metrics` endpoint |
| **Python / FastAPI** | REST API development, middleware, Pytest test suite, Prometheus text format metrics |
| **Security** | Non-root containers, masked CI variables, `seccompProfile: RuntimeDefault`, token hygiene |
| **Autonomous Systems & Governance** | OPA/Rego deterministic policies, risk engine, distributed lease locking, monotonic fencing |
| **Troubleshooting** | 3 CI pipeline failures diagnosed from first principles and fixed with targeted commits |

---

## Repository Links

| Project | GitHub | GitLab | Notes |
|---------|--------|--------|-------|
| kube-obs | [github.com/SUPRAVAT001/kube-obs](https://github.com/SUPRAVAT001/kube-obs) | — | Production-ready baseline (12/12 checks) |
| git-argo | [github.com/SUPRAVAT001/git-argo](https://github.com/SUPRAVAT001/git-argo) | [gitlab.com/supravatdash7399/git-argo](https://gitlab.com/supravatdash7399/git-argo) | Live verified SaaS pipeline #3045047835 |
| devops-jarvis | Local Active Workspace | — | Milestone 9 Phase 3 verified (1,419 tests) |

---

> **Accuracy note**: All metrics, pipeline IDs, commit SHAs, endpoint responses, and execution times cited in this document reflect actual verified execution. No benchmarks, production traffic claims, enterprise adoption, or cloud deployments are stated. Both projects run on a local Minikube cluster (WSL2 / Ubuntu) unless specifically noted as GitLab SaaS execution.

