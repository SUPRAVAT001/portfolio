# Professional Profile

**Supravat Dash**  
DevOps Engineer · Platform Engineer · Site Reliability Engineer  
GitHub: [github.com/SUPRAVAT001](https://github.com/SUPRAVAT001) · GitLab: [gitlab.com/supravatdash7399](https://gitlab.com/supravatdash7399) · Location: India (Remote / Hybrid)

---

## 1. Technical Introduction

I am a Systems and DevOps Engineer focused on building robust, observable, and automated delivery platforms. My work centers on the intersection of container orchestration, declarative continuous delivery (GitOps), full-stack Kubernetes observability, and governed autonomous infrastructure control planes.

I believe in **systems that communicate their own state**, **pipelines that eliminate human error through deterministic policy**, and **infrastructure that heals itself declaratively**.

Rather than relying on toy examples or guided tutorials, I architect and build production-pattern systems from scratch. Across my projects, I have implemented end-to-end telemetry pipelines, five-stage multi-platform CI/CD automation with unprivileged container builds, and autonomous AI-driven SRE control planes governed by deterministic safety gates.

---

## 2. Engineering Specialization & Core Pillars

### A. Linux & Infrastructure Foundations
* Deep understanding of Linux kernel primitives: namespaces (PID, net, mount, IPC, UTS, user), control groups (cgroups v1/v2), memory accounting, swap management, and process lifecycles.
* Practical systems administration in Ubuntu/Debian environments, WSL2 virtualization tuning, kernel resource allocation, and storage troubleshooting.
* CLI proficiency with POSIX shell scripting, process debugging (`ps`, `top`, `htop`, `/proc` filesystem), network inspection (`netstat`, `ss`, `curl`, `dig`), and log analysis.

### B. Containerization & Pod Security
* Hardened, multi-stage Docker builds using minimal base images (`python:3.12-slim`, `alpine`).
* Least-privilege container execution: strictly non-root users (UID/GID 10001), stripping Linux capabilities (`drop: [ALL]`), and enforcing default seccomp profiles (`RuntimeDefault`).
* Docker daemon internals, Docker-in-Docker (DinD) with mTLS authentication, volume management, and `.dockerignore` context hygiene.

### C. Kubernetes Platform Engineering
* Declarative workload management across Deployments, StatefulSets, DaemonSets, Services (ClusterIP, NodePort), and ConfigMaps.
* Pod scheduling, resource boundaries (conservative CPU/memory requests and limits), and health lifecycle management using decoupled liveness and readiness HTTP probes.
* Ingress networking via NGINX Ingress Controller with SNI-based TLS termination.
* Package management with Helm v3: authoring parameterizable charts, defining template helpers (`_helpers.tpl`), managing release lifecycles, and validating via `helm lint`.

### D. CI/CD & Declarative GitOps
* Multi-stage pipeline automation in GitLab CI/CD: static code compilation, YAML schema validation, Pytest execution with JUnit XML reporting, container build/publish, and automated GitOps repository promotion.
* GitOps continuous delivery with Argo CD: automated reconciliation loops, out-of-band configuration drift detection, automated self-healing (`selfHeal: true`), and declarative rollback via `git revert`.
* Separation of concerns: decoupling CI code execution (GitLab) from immutable deployment configuration (GitHub as source of truth).
* Secret hygiene: using masked, protected CI variables and avoiding secrets in source control.

### E. Monitoring, Telemetry & SRE
* Prometheus metrics collection: time-series database architecture, scrape configuration, target discovery via Kubernetes pod annotations, and PromQL query authoring.
* Incident routing with Alertmanager: rule evaluation, multi-stage alert lifecycle states (Inactive → Pending → Firing → Resolved), grouping, deduplication, and webhook dispatch.
* Visualization as Code: auto-provisioning Grafana datasources and operational dashboards via Kubernetes ConfigMaps and sidecars.
* System and application telemetry: exposing custom Prometheus text metrics in Python/FastAPI (`counters`, `gauges`), gathering host metrics via Node Exporter, and cluster state via kube-state-metrics.

### F. Python & API Engineering
* Async web service development using Python 3.12 and FastAPI.
* Custom middleware for HTTP request tracing, latency tracking, and metric counters.
* Automated testing with Pytest, `TestClient`, test fixtures, and JUnit XML report generation.
* Database management with PostgreSQL 16, SQLAlchemy 2.0 ORM, and Alembic migrations.

### G. Governed AI Autonomy & SRE Control Planes
* Architecting safe, bounded-autonomy AI agents for infrastructure operations via **DevOps Jarvis**.
* Enforcing deterministic execution gates: LLMs extract intent and generate plans, but **never execute commands directly**.
* Implementing multi-stage safety controls: OPA/Rego deterministic policy evaluation, static and live risk scoring, dry-run simulation, human-in-the-loop approvals, distributed PostgreSQL row-level lease locking, and monotonic fencing tokens.

---

## 3. Experience & Credibility Framework

To ensure complete transparency with recruiters, hiring managers, and interviewers, my technical background is categorized as follows:

| Category | Description | Verification / Evidence |
| :--- | :--- | :--- |
| **Independent Engineering Projects** | End-to-end platforms designed, implemented, debugged, and operated independently. | Full repositories, commits, and runbooks in [`projects/`](../projects). |
| **Verified Practical Implementation** | Systems actively executed, tested, and validated against live Kubernetes clusters and GitLab SaaS. | 13 high-res screenshots, live API endpoints, 1,419 passing test cases, and public pipeline runs. |
| **Operational Troubleshooting** | First-principles debugging of real issues (kernel OOM, DinD entrypoints, YAML parsers, lease race conditions). | Documented in [`interview/TROUBLESHOOTING_SCENARIOS.md`](../interview/TROUBLESHOOTING_SCENARIOS.md). |
| **Conceptual & Emerging Knowledge** | Industry patterns studied, understood, and planned for future production adoption (AWS/GCP managed control planes, Terraform, Vault, Service Mesh). | Documented in [`roadmap/CAREER_ROADMAP.md`](../roadmap/CAREER_ROADMAP.md). |

---

## 4. Engineering Philosophy

1. **Declarative Over Imperative**: If a change isn't committed to Git, it doesn't exist. Manual `kubectl` mutations in production are defects.
2. **Deterministic Safety Over Model Trust**: In AI-assisted operations, AI proposes, but deterministic code validates, simulates, and bounds execution.
3. **Observability Precedes Reliability**: You cannot stabilize or scale what you cannot measure. Instrumentation is a day-one requirement, not a day-two afterthought.
4. **Least Privilege by Default**: Containers must not run as root. Services must not automount API tokens they do not require. Pipelines must not hold cluster credentials.

