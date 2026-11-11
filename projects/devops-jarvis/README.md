# DevOps Jarvis — Governed AI SRE & Progressive Delivery Control Plane

**Architecture**: [Architecture Specification](ARCHITECTURE.md)  
**Status**: Active Local Engineering Platform — **Milestone 9 Phase 3 Complete** (Under Development, Not Commercial Production)

---

## Problem Statement

Granting Large Language Models unrestricted shell or Kubernetes admin access creates severe operational hazards: hallucinated commands, prompt injection, race conditions between concurrent workflows, and non-deterministic changes bypassing safety checks.

**DevOps Jarvis** addresses this through **Governed Bounded Autonomy**: AI reasoning extracts operational intent and proposes plans, while deterministic Python controllers, Open Policy Agent (OPA) rules, risk scoring, pre-execution simulation, distributed database leases, and metric-driven canary gates retain strict control over cluster mutations.

---

## Key Implemented Capabilities (M1 – M9 Phase 3)

* **Deterministic Execution Choke Point (`ExecutionController`)**: Every workload deployment, rollback, or traffic shift must pass risk scoring (`RiskEngine`), policy evaluation (`PolicyEngine` + OPA `m1.rego`), dry-run simulation (`SimulationService`), and human approval gates (`ApprovalService`) before reaching a Kubernetes executor.
* **Metric-Driven Progressive Delivery (`CanaryEvaluator`)**: Drives multi-stage canary traffic progression (10% → 25% → 50% → 100%) via NGINX Ingress weight annotations while querying live Prometheus telemetry. Enforces fail-closed epistemic invariants (`UNKNOWN != SAFE`, `STALE != FRESH`) so missing or insufficient samples pause progression rather than advancing.
* **Distributed Execution Leases (`PostgresIdempotencyStore`)**: Uses PostgreSQL row-level locks (`SELECT ... FOR UPDATE`), monotonic fencing tokens, bounded lease TTLs, and payload idempotency hashes to prevent concurrent workers or stale zombie processes from issuing conflicting mutations.
* **Startup Recovery & Reconciliation Loops (M9 Phase 3)**: Detects interrupted workflows with expired leases after restarts, executes authoritative live cluster readbacks, and safely reconciles or resumes in-flight operations.
* **Fail-Closed Runtime Invariants**: Live Kubernetes/host actuation stays disabled by default (`JARVIS_ALLOW_LIVE_CANARY_ACTUATION="false"`), and tenant boundaries scope every task, rollout, event, and lease.

---

## Development Status & Scope Boundaries

| Phase / Area | Status | Verification Evidence |
| :--- | :--- | :--- |
| **M1 – M6: Core Control Plane, Incident RCA & Context Graph** | **Completed** | Deterministic planning, OPA gating (`m1.rego`), dependency blast-radius graph, and post-change learning calibrated against unit/integration suites. |
| **M7 – M8: Canary State Machine & Live Actuation** | **Completed** | Validated live NGINX Ingress weight splitting (`25%` target vs `21%` observed over 100 probes) and Prometheus abort tests on error-rate surges on Minikube. |
| **M9 Phases 1–3: Autonomy, Leases & Crash Recovery** | **Completed** | End-to-end 4-stage autonomous Minikube canary promotion (`64.12s`); **1,419 passed, 3 skipped, 0 failed** tests; Alembic head revision `c5d6e7f8a9b0`. |
| **Cloud Cluster Providers (M3 EKS/GKE/AKS)** | **Foundation Only** | Provider-neutral connectivity & short-lived credential foundations verified via mocked/unit suites; not deployed to live commercial AWS/GCP/Azure fleets. |
| **M9 Phase 4+ & Multi-Cluster SaaS Scale** | **Planned** | Further production hardening, enterprise SSO, and multi-region fleet coordination remain under development. |

> **Transparency Note**: DevOps Jarvis is an active engineering platform validated in a local Docker Compose staging environment (FastAPI + PostgreSQL 17 + OPA `0.68.0`) and a single-node Minikube test cluster. It is not presented as a deployed multi-tenant SaaS product.

