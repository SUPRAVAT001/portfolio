# Project Overview: Autonomous AI SRE Control Plane (`devops-jarvis`)

**Status**: Active Engineering Development — **Milestone 9 Phase 3 Complete & Verified**  
**Active Test Suite**: **1,419 Passed**, 3 Skipped, 0 Failures (100% Deterministic Baseline)  
**Primary Domain**: Governed AI Systems, Autonomous SRE, Policy Enforcement, Distributed Concurrency

---

## 1. Problem Statement

The rise of Large Language Models (LLMs) in software engineering has created dangerous patterns in infrastructure operations:
* **The "Unbounded Execution" Anti-Pattern**: Giving AI agents raw shell access, broad Kubernetes cluster-admin credentials, or direct cloud CLI execution. An LLM hallucination or prompt injection can wipe out production clusters or delete critical databases.
* **Non-Deterministic Operations**: Stochastic models cannot guarantee compliance with organizational safety policies, regulatory controls, or progressive delivery safety gates.
* **Concurrency Collisions**: Multiple AI workflows attempting simultaneous infrastructure mutations lead to split-brain states and race conditions.

**DevOps Jarvis** is an autonomous AI DevOps and SRE control plane engineered with **Governed Bounded Autonomy**: LLMs extract natural language intent, correlate observability telemetry, and synthesize remediation strategies, but **are cryptographically and architecturally prevented from directly mutating infrastructure**.

---

## 2. Core Architectural Principles & Invariants

```
                                  GOVERNED BOUNDED AUTONOMY
                                  
  Natural Language Intent        Deterministic Safety Gates         Live Cloud Infrastructure
 ┌───────────────────────┐      ┌───────────────────────────┐      ┌─────────────────────────┐
 │   LLM Intelligence    │      │    ExecutionController    │      │   Kubernetes Cluster    │
 │  • Intent Extraction  │ ───> │  1. OPA/Rego Policy Gate  │ ───> │  • NGINX Ingress Canary │
 │  • Telemetry Analysis │      │  2. Dynamic Risk Scoring  │      │  • Workload Actuation   │
 │  • Remediation Plans  │      │  3. Dry-Run Simulation    │      │  • Prometheus Telemetry │
 └───────────────────────┘      │  4. Human Approval Gate   │      └─────────────────────────┘
   (Proposes Mutations)         │  5. Distributed Leases    │         (Guaranteed Safe State)
                                └───────────────────────────┘
                                   (Executes Deterministically)
```

1. **Deterministic Execution Gate**: All operations must flow through a mandatory choke point (`ExecutionController`). If any gate (policy, risk, simulation, approval) rejects the plan, execution halts immediately.
2. **Epistemic Invariants**:
   * `UNKNOWN != SAFE`: Missing telemetry or insufficient metric samples automatically halt progressive canary rollouts.
   * `STALE != FRESH`: Outdated metrics pause progression rather than advancing on assumed health.
3. **Distributed Concurrency & Fencing Safety**: PostgreSQL row-level locks (`SELECT ... FOR UPDATE`) back distributed execution leases, and monotonic fencing tokens protect against zombie workers committing conflicting results.
4. **Self-Healing Reconciliation Loops**: Interrupted workflows (e.g., node reboot mid-rollout) are detected and recovered autonomously on startup and through periodic ticks using authoritative cluster readbacks.

---

## 3. Technology Stack

| Layer | Component | Version / Implementation | Role |
| :--- | :--- | :--- | :--- |
| **Backend Core** | Python / FastAPI | Python 3.12, FastAPI 0.115+ | Async control plane APIs and background event loops |
| **Persistence** | PostgreSQL | PostgreSQL 16 | ACID transaction storage, row-level distributed locking |
| **ORM & Migrations**| SQLAlchemy / Alembic | SQLAlchemy 2.0 / Alembic | Schema versioning at revision `c5d6e7f8a9b0 (head)` |
| **Policy Engine** | Open Policy Agent | OPA / Rego | Declarative, deterministic policy evaluation before actuation |
| **Telemetry Ingestion**| Prometheus | Prometheus v2.50+ | Real-time metric querying for canary health evaluation |
| **Target Runtime** | Kubernetes | Minikube v1.35.0 (K8s v1.32.0)| Workload actuation, NGINX Ingress canary routing |
| **Verification** | Pytest | Pytest 8.4+ | 1,419 automated unit, integration, and browser QA tests |

---

## 4. Current Implementation Scope & Development Boundaries

To maintain engineering transparency:
* **Completed & Verified (Milestones 1–9 Phase 3)**: Core control plane, natural language processing, engineering context graph, post-change accuracy learning, progressive delivery canary rollouts (10% → 25% → 50% → 100%), distributed lease locking with monotonic fencing, and interrupted workflow recovery.
* **Under Active Development (Milestone 10+)**: Multi-cloud IAM federation, cross-cluster service mesh canary actuation, and enterprise multi-region disaster recovery coordination.

