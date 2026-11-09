# Projects Portfolio

A technical catalog of three independently engineered cloud-native infrastructure, continuous delivery, and autonomous operations platforms.

---

## Portfolio Projects Matrix

| Project | Domain | Key Technologies | Status | Repositories & Verification |
| :--- | :--- | :--- | :--- | :--- |
| **`kube-obs`**<br>Kubernetes Observability Platform | Observability & Telemetry | Prometheus, Grafana, Alertmanager, Node Exporter, Kube-State-Metrics, NGINX Ingress, TLS, Helm | Production-Ready Baseline | [GitHub](https://github.com/SUPRAVAT001/kube-obs) · 12/12 Automated Checks Passed · 7 High-Res Screenshots |
| **`git-argo`**<br>GitOps Continuous Delivery Platform | CI/CD & Declarative GitOps | GitLab CI/CD, GitLab Container Registry, Argo CD, GitHub, Helm, FastAPI, Docker, Kubernetes | Live SaaS Verified | [GitHub](https://github.com/SUPRAVAT001/git-argo) · [GitLab](https://gitlab.com/supravatdash7399/git-argo) · Pipeline #3045047835 Passed · 13 Verified Screenshots |
| **`devops-jarvis`**<br>Autonomous AI SRE Control Plane | Governed Autonomous SRE | Python 3.12, FastAPI, PostgreSQL 16, OPA/Rego, SQLAlchemy, Docker Compose, Kubernetes, Prometheus | Milestone 9 Phase 3 Complete | Under Active Development · 1,419 Automated Tests Passing (0 Failures) · Governed Bounded Autonomy |

---

## Detailed Project Navigation

Each project contains in-depth documentation covering architecture, technical decisions, implementation highlights, and verified evidence:

### 1. [Kubernetes Observability Platform (`kube-obs`)](kube-obs/PROJECT_OVERVIEW.md)
* [**Project Overview**](kube-obs/PROJECT_OVERVIEW.md): Problem statement, design goals, and complete technology stack.
* [**System Architecture**](kube-obs/ARCHITECTURE.md): Multi-tier metrics scraping, Alertmanager routing trees, and TLS ingress flows.
* [**Technical Highlights**](kube-obs/TECHNICAL_HIGHLIGHTS.md): 136 alerting rules, failure simulation experiments, and the 12-point automated test suite.

### 2. [GitOps Continuous Delivery Platform (`git-argo`)](git-argo/PROJECT_OVERVIEW.md)
* [**Project Overview**](git-argo/PROJECT_OVERVIEW.md): Decoupled CI/CD architecture, separation of concerns, and endpoints.
* [**System Architecture**](git-argo/ARCHITECTURE.md): 5-stage GitLab CI DAG, Docker DinD container builds, and Argo CD reconciliation state machine.
* [**Technical Highlights**](git-argo/TECHNICAL_HIGHLIGHTS.md): Pipeline troubleshooting cases, drift detection self-healing, and Git-driven rollbacks.

### 3. [Autonomous AI SRE Control Plane (`devops-jarvis`)](devops-jarvis/PROJECT_OVERVIEW.md)
* [**Project Overview**](devops-jarvis/PROJECT_OVERVIEW.md): Bounded autonomy philosophy, safety invariants, and core problem statement.
* [**System Architecture**](devops-jarvis/ARCHITECTURE.md): 5-zone architecture, deterministic execution choke points, OPA policy gates, and distributed lease locking.
* [**Implementation Status**](devops-jarvis/IMPLEMENTATION_STATUS.md): Milestone progress ledger (M1–M9 Phase 3 verified), 1,419 passing test suite breakdown, and active development boundaries.

---

## Cross-Project Synergy

These three platforms reflect a cohesive cloud-native engineering progression:
1. **`kube-obs`** provides the telemetry foundation: without metrics and alerts, automated operations are impossible.
2. **`git-argo`** provides the delivery foundation: automated code testing, container publishing, and declarative GitOps reconciliation.
3. **`devops-jarvis`** builds on both: reading telemetry from Prometheus (`kube-obs`), executing progressive rollouts via Kubernetes/NGINX (`git-argo`), and self-healing systems through governed, bounded autonomous loops.

