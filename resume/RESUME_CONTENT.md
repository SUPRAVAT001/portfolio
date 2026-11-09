# Master Resume Content Source

**Supravat Dash**  
DevOps Engineer · Platform Engineer · Site Reliability Engineer · Cloud Engineer  
GitHub: [github.com/SUPRAVAT001](https://github.com/SUPRAVAT001) · GitLab: [gitlab.com/supravatdash7399](https://gitlab.com/supravatdash7399) · Location: India (Remote / Hybrid)

---

## 1. Universal Professional Summary (Core Truth)

DevOps and Systems Engineer with demonstrated hands-on expertise in **Kubernetes platform engineering**, **GitOps continuous delivery**, **cloud-native observability**, and **autonomous infrastructure automation**. Proven ability to design, build, and operate resilient systems from scratch:
* Authored a 5-stage GitLab CI/CD pipeline deploying unprivileged container workloads to Kubernetes via Argo CD with continuous reconciliation, drift detection, and automated self-healing.
* Engineered a complete Kubernetes telemetry stack integrating Prometheus, Grafana, Alertmanager, and NGINX Ingress with TLS, validating alert pipelines through controlled pod failures and automated 12-point health suites.
* Developed an autonomous AI-driven SRE control plane (DevOps Jarvis) incorporating deterministic OPA policy gates, risk assessment engines, pre-execution simulation, and distributed PostgreSQL lease locking backed by 1,419 passing automated test cases.
* Deep practical understanding of Linux kernel primitives (namespaces, cgroups, memory accounting), container security hardening (non-root UID 10001, capability stripping, seccomp), Helm packaging, and Python/FastAPI backend microservice development.

---

## 2. Role-Oriented Summaries (Tailored Formats)

### A. DevOps Engineer
> DevOps Engineer specializing in automated CI/CD pipelines, containerization security, and declarative continuous delivery. Demonstrated expertise building multi-stage GitLab CI/CD pipelines with unprivileged Docker-in-Docker builds and GitLab Container Registry publishing. Implemented declarative GitOps workflows using Argo CD, demonstrating continuous drift detection, automated self-healing, and Git-driven rollbacks across Kubernetes workloads.

### B. Cloud Engineer
> Cloud Engineer with practical experience architecting cloud-native container workloads, Helm-based packaging, and secure ingress networking. Implemented SNI-based TLS termination with NGINX Ingress, decoupled stateless compute from persistent storage via PVCs, and automated cloud delivery workflows bridging hosted GitLab SaaS runners with Kubernetes infrastructure. Focused on declarative infrastructure, least-privilege security contexts, and container runtime isolation.

### C. Platform Engineer
> Platform Engineer focused on developer enablement, Kubernetes cluster administration, and declarative platform tooling. Authored reusable, parameterizable Helm charts with strict securityContext hardening (non-root UID 10001, capability drops, seccomp profiles) and decoupled environment ConfigMaps. Engineered deterministic local simulation harnesses and established Git as the single source of truth for platform deployments via Argo CD Application controllers.

### D. Site Reliability Engineer (SRE)
> Site Reliability Engineer experienced in end-to-end telemetry engineering, proactive alerting, and autonomous self-healing systems. Architected full-stack Kubernetes observability with Prometheus, Alertmanager, and Grafana; authored 136 alerting rules and validated incident notification pipelines under controlled failure scenarios. Built autonomous canary evaluation engines driving metric-driven progressive delivery under strict epistemic invariants (`UNKNOWN != SAFE`).

---

## 3. Technical Skills Inventory

* **Orchestration & Packaging**: Kubernetes (Deployments, StatefulSets, DaemonSets, Services, Ingress, Probes, Resource Limits), Helm v3 (Chart authoring, templates, helpers, linting), Minikube runtime.
* **CI/CD & GitOps**: GitLab CI/CD (5-stage DAG pipelines, artifacts, cache, rules), Argo CD (Application CRs, selfHeal, drift detection), GitHub, Docker-in-Docker (DinD), GitLab Container Registry.
* **Observability & SRE**: Prometheus Server (TSDB, PromQL, scrape configs, service discovery), Alertmanager (route trees, deduplication, webhook dispatch), Grafana (dashboards as code), Node Exporter, Kube-State-Metrics.
* **Security & Containerization**: Docker (multi-stage unprivileged builds), Linux kernel namespaces, cgroups v1/v2, non-root execution (UID 10001), capability dropping (`ALL`), seccomp (`RuntimeDefault`), token hygiene (`automount: false`).
* **Governance & Autonomous Systems**: Open Policy Agent (OPA/Rego), Risk assessment engines, PostgreSQL 16 distributed row-level locking (`SELECT ... FOR UPDATE`), monotonic fencing tokens, dry-run simulation.
* **Languages & Frameworks**: Python 3.12 (FastAPI, async/await, middleware, Pydantic), POSIX Bash shell scripting, SQL (PostgreSQL), Pytest (fixtures, TestClient, JUnit XML), YAML.

---

## 4. Key Projects for Resume Inclusion

### Project 1: GitOps CI/CD Delivery Platform (`git-argo`)
* **Repository**: [github.com/SUPRAVAT001/git-argo](https://github.com/SUPRAVAT001/git-argo) · [gitlab.com/supravatdash7399/git-argo](https://gitlab.com/supravatdash7399/git-argo)
* **Highlights**:
  * Designed a 5-stage `.gitlab-ci.yml` pipeline that compiles code, executes Pytest with JUnit XML reports, builds unprivileged Docker images via DinD, and publishes to GitLab Container Registry.
  * Configured automated promotion committing immutable commit SHAs (`${CI_COMMIT_SHORT_SHA}`) to GitHub via a masked `GITOPS_GITHUB_TOKEN`, triggering Argo CD synchronization.
  * Verified live on GitLab SaaS (Pipeline #3045047835) and demonstrated automated drift detection (`kubectl scale` to 3 auto-remediated to 1) and declarative Git rollback (`git revert`).
  * Hardened microservice workload with non-root security context (UID 10001), capability stripping (`ALL`), and decoupled liveness/readiness probes.

### Project 2: Kubernetes Observability Platform (`kube-obs`)
* **Repository**: [github.com/SUPRAVAT001/kube-obs](https://github.com/SUPRAVAT001/kube-obs)
* **Highlights**:
  * Deployed a production-pattern telemetry stack on Kubernetes using Helm, integrating Prometheus for metrics ingestion, Alertmanager for incident routing, and Grafana for dashboards.
  * Configured host and cluster telemetry via Node Exporter and Kube-State-Metrics alongside custom `/metrics` instrumentation in a Python microservice using pod annotation auto-discovery.
  * Authored 136 alerting rules and validated the alert lifecycle (Pending → Firing → Resolved) and webhook notification dispatch via controlled pod crash-loop simulations.
  * Implemented secure HTTPS access to dashboards and services via NGINX Ingress Controller with SNI-based TLS secret termination.

### Project 3: Autonomous AI SRE Control Plane (`devops-jarvis`)
* **Status**: Under Active Development — Milestone 9 Phase 3 Complete (1,419 passing tests)
* **Highlights**:
  * Engineered a Governed Bounded Autonomy control plane in Python/FastAPI where LLMs propose actions but are blocked from direct cluster mutation by a mandatory `ExecutionController` choke point.
  * Integrated Open Policy Agent (OPA/Rego), dynamic blast-radius risk scoring, and two-phase dry-run simulation to validate mutations before execution.
  * Implemented autonomous progressive delivery driving multi-stage canary traffic splitting (10% → 25% → 50% → 100%) against live Prometheus telemetry with strict epistemic invariants (`UNKNOWN != SAFE`).
  * Enforced distributed lease locking with PostgreSQL 16 row-level locks and monotonic fencing tokens to prevent zombie worker collisions and ensure self-healing after process interruption.

---

## 5. Verified Engineering Achievements (Quantified Proof)

* **100% Pipeline Automation**: GitLab SaaS Pipeline #3045047835 passed all 5 stages in 3m 7s with zero manual intervention.
* **Zero Downtime Rollbacks**: Executed declarative rollback of Kubernetes workloads purely via Git revert, maintaining continuous endpoint availability.
* **1,419 Passing Test Cases**: Comprehensive unit, integration, and browser QA test suite in DevOps Jarvis with zero regressions.
* **136 Alerting Rules**: Complete alerting rules covering host, container, and application saturation thresholds.
* **Sub-15s Drift Remediation**: Out-of-band cluster modifications automatically detected and reconciled by Argo CD within seconds.

