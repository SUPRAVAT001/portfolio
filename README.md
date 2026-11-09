# Supravat Dash — Systems, DevOps & Platform Engineering Portfolio

[![GitHub Profile](https://img.shields.io/badge/GitHub-SUPRAVAT001-181717?logo=github&logoColor=white)](https://github.com/SUPRAVAT001)
[![GitLab Profile](https://img.shields.io/badge/GitLab-supravatdash7399-FC6D26?logo=gitlab&logoColor=white)](https://gitlab.com/supravatdash7399)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.35.1-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Argo CD](https://img.shields.io/badge/Argo%20CD-v3.6.1-EF7B4D?logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![GitLab CI](https://img.shields.io/badge/GitLab%20CI%2FCD-Pipeline%20Ready-FC6D26?logo=gitlab&logoColor=white)](https://gitlab.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-v3.15.1-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-v13.3.0-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![Helm](https://img.shields.io/badge/Helm-v3.22.1-0F1689?logo=helm&logoColor=white)](https://helm.sh/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)](https://python.org/)
[![Jarvis Tests](https://img.shields.io/badge/Jarvis%20Tests-1%2C419%20Passing-brightgreen)](#project-3-autonomous-ai-sre-control-plane-devops-jarvis)

Welcome to my centralized DevOps, Platform Engineering, and Site Reliability Engineering portfolio. This repository serves as the definitive source of truth for my technical profile, architectural designs, verifiable operational evidence, and engineering achievements across three production-pattern platforms.

---

## 1. Professional Focus & Core Specialization

My engineering practice centers on four foundational disciplines:

* **DevOps & Infrastructure Automation**: Designing end-to-end continuous integration and deployment pipelines that eliminate manual operational toil through automated testing, immutable container tagging, and policy-as-code.
* **Cloud & Kubernetes Platform Engineering**: Building declarative, hardened runtime environments using Kubernetes, Helm v3, and unprivileged container runtimes with strict Linux capability stripping and non-root execution.
* **Continuous Delivery & Declarative GitOps**: Decoupling CI build concerns from deployment state, leveraging Argo CD to continuously reconcile desired Git state against live cluster reality with automated drift detection and self-healing.
* **Observability & Site Reliability Engineering (SRE)**: Implementing full-stack telemetry pipelines (Prometheus, Grafana, Alertmanager) that ingest host, cluster, and application metrics, evaluate complex multi-tier alerting rules, and route incidents to webhook endpoints.
* **AI-Driven Infrastructure Operations (AIOps)**: Architecting governed autonomous control planes that leverage AI for natural language intent extraction while enforcing deterministic execution gates via Open Policy Agent (OPA) and distributed lease concurrency.

---

## 2. Featured Engineering Platforms

### Project 1: Kubernetes Observability Platform (`kube-obs`)
> **Full-Stack Telemetry Ingestion, Alerting & Visualization as Code**  
> GitHub Repository: [github.com/SUPRAVAT001/kube-obs](https://github.com/SUPRAVAT001/kube-obs) · [Documentation](projects/kube-obs/PROJECT_OVERVIEW.md) · [Architecture](projects/kube-obs/ARCHITECTURE.md)

* **Problem Solved**: Microservices operating in Kubernetes without centralized telemetry suffer from silent failures (pod crash loops, cgroup memory throttling, and network partitions) that remain undetected until users experience outages.
* **Architecture Overview**:
  ```
  Host Metrics (Node Exporter :9100)       ──┐
  Cluster State (kube-state-metrics :8080)  ──┼──> Prometheus TSDB ──> Alertmanager ──> Webhook Dispatch
  Application Telemetry (FastAPI :8080)     ──┘          │
                                                         ▼
  NGINX Ingress (TLS Termination :443)  ───────────> Grafana Dashboards (ConfigMap Auto-Provisioned)
  ```
* **Technology Stack**: Kubernetes v1.35.1, Prometheus Server v3.15.1, Grafana v13.3.0, Alertmanager v0.28.0, Node Exporter v1.9.0, Kube-State-Metrics v2.15.0, NGINX Ingress Controller v1.14.0, Helm v3.22.0.
* **Key Capabilities**:
  * 136 production alerting rules evaluating host, container, and application saturation thresholds.
  * Multi-stage alert lifecycle evaluation (Inactive → Pending → Firing → Resolved) with webhook dispatch.
  * Dynamic target discovery via Kubernetes pod annotations (`prometheus.io/scrape: "true"`).
  * SNI-based TLS termination via Kubernetes TLS Secrets for `grafana.local`, `prometheus.local`, and `app.local`.
* **Verified Evidence**: 12/12 automated platform checks passed (`scripts/validate.sh`). Complete visual evidence archived in [`evidence/kube-obs/`](evidence/kube-obs/).

---

### Project 2: GitOps CI/CD Delivery Platform (`git-argo`)
> **Automated Cloud Delivery: GitLab CI/CD → Registry → GitHub → Argo CD → Kubernetes**  
> GitHub (GitOps State): [github.com/SUPRAVAT001/git-argo](https://github.com/SUPRAVAT001/git-argo) · GitLab (CI/CD): [gitlab.com/supravatdash7399/git-argo](https://gitlab.com/supravatdash7399/git-argo) · [Documentation](projects/git-argo/PROJECT_OVERVIEW.md) · [Architecture](projects/git-argo/ARCHITECTURE.md)

* **Problem Solved**: Eliminates the "CI pushes to Kubernetes" anti-pattern where CI runners hold cluster admin credentials and execute imperative commands, risking cluster compromise and untracked configuration drift.
* **Architecture Overview**:
  ```
  Developer Push ──> GitLab CI/CD (5 Stages) ──> GitLab Container Registry (:commit-sha)
                           │
                           └──> Stage 5: Update GitOps Tag via Masked Token
                                     │
                                     ▼
  Argo CD Controller <── Polls ── GitHub Repository (Source of Truth: values.yaml)
         │
         ▼ (Declarative Reconciliation & Self-Healing)
  Kubernetes Cluster (Namespace: gitops-demo | Non-Root Container UID 10001)
  ```
* **Technology Stack**: GitLab CI/CD SaaS, GitLab Container Registry, Argo CD v3.6.1, GitHub, Helm v3.22.1, Docker v27 (DinD over mTLS), FastAPI (Python 3.12), Pytest v8.4.
* **Key Capabilities**:
  * Deterministic immutable commit SHA tagging (`${CI_COMMIT_SHORT_SHA}`) replacing mutable `latest` tags.
  * Continuous out-of-band drift detection: manual replica scaling immediately detected as `OutOfSync`.
  * Automated self-healing (`selfHeal: true`): rogue pods terminated within seconds to restore declared Git state.
  * Declarative zero-downtime rollback executed entirely via Git (`git revert`) without imperative cluster access.
  * Unprivileged container hardening: non-root user `appuser` (UID 10001), `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`.
* **Verified Evidence**: Hosted GitLab SaaS [Pipeline #3045047835](https://gitlab.com/supravatdash7399/git-argo/-/pipelines/3045047835) passed 100% in 3m 7s. Complete visual evidence archived in [`evidence/git-argo/`](evidence/git-argo/).

---

### Project 3: Autonomous AI SRE Control Plane (`devops-jarvis`)
> **Governed Bounded Autonomy Control Plane with Deterministic Safety Gates**  
> Status: Active Engineering Development (Milestone 9 Phase 3 Complete) · [Documentation](projects/devops-jarvis/PROJECT_OVERVIEW.md) · [Architecture](projects/devops-jarvis/ARCHITECTURE.md) · [Status Ledger](projects/devops-jarvis/IMPLEMENTATION_STATUS.md)

* **Problem Solved**: Unbounded AI agents operating with raw shell access introduce catastrophic operational risk from hallucinations and prompt injection. Jarvis enforces that **AI proposes intent, but deterministic code validates and executes**.
* **Architecture Overview**:
  ```
  Natural Language Intent ──> Cognitive Engine (LLM Intent Extraction)
                                     │
                                     ▼
  ExecutionController Choke Point ──> [OPA/Rego Policy] ──> [Risk Scoring] ──> [Dry-Run Simulation]
                                     │
                                     ▼
  Distributed Lease Concurrency   ──> PostgreSQL 16 Leases + Monotonic Fencing Tokens
                                     │
                                     ▼
  Progressive Delivery Actuation  ──> Autonomous Canary Loop (10% → 25% → 50% → 100%)
                                      Prometheus Telemetry Invariants: UNKNOWN != SAFE
  ```
* **Technology Stack**: Python 3.12, FastAPI, PostgreSQL 16, SQLAlchemy 2.0, Alembic, Open Policy Agent (OPA/Rego), Prometheus, NGINX Ingress, Minikube Kubernetes v1.32.0.
* **Key Capabilities**:
  * Mandatory execution choke point evaluating declarative Rego policies before cluster mutation.
  * Dynamic blast-radius risk scoring evaluating replica count, dependency depth, and environment tiers.
  * Distributed lease locking with PostgreSQL row-level locks and monotonic fencing tokens preventing split-brain mutations.
  * Self-healing reconciliation loops for startup and periodic ticks that recover interrupted workflows autonomously.
* **Verified Evidence**: **1,419 automated tests passing** (0 failures, 0 regressions) across unit, integration, and browser QA suites. Database schema at Alembic revision `c5d6e7f8a9b0 (head)`.

---

## 3. Technical Skills Matrix

Competencies classified strictly according to verified implementation evidence:

| Domain | Implemented & Verified in Projects | Working Operational Knowledge | Conceptual / Roadmap |
| :--- | :--- | :--- | :--- |
| **Containers & Orchestration** | Docker (multi-stage unprivileged builds), Kubernetes (Deployments, StatefulSets, DaemonSets, Services, Ingress, Probes, Limits), Helm v3 (Chart authoring, linting, templating), Minikube | Cgroup limits, Namespace isolation, Secret & ConfigMap mounting, PV/PVC persistence | AWS EKS, GCP GKE, Cluster API, KEDA |
| **CI/CD & GitOps** | GitLab CI/CD (5-stage DAG pipelines, artifacts, cache, rules), Argo CD (Application CRs, selfHeal, drift detection), GitHub, Docker-in-Docker (DinD mTLS), GitLab Container Registry | Immutable commit SHA tagging, automated GitOps promotion commits, Git revert rollbacks | Argo CD ApplicationSets, Flagger canary automation, GitHub Actions |
| **Observability & SRE** | Prometheus Server (TSDB, PromQL, scrape configs, service discovery), Alertmanager (route trees, deduplication, webhook dispatch), Grafana (dashboards as code), Node Exporter, Kube-State-Metrics | Custom `/metrics` Python instrumentation, PromQL rate/histogram queries, 136 alerting rules | OpenTelemetry (OTel), Grafana Tempo, Loki distributed logging |
| **Programming & Scripting** | Python 3.12 (FastAPI, async/await, middleware, Pydantic), POSIX Bash shell scripting, SQL (PostgreSQL 16), Pytest (TestClient, fixtures, JUnit XML) | Text processing (`sed`, `awk`, `grep`), Jinja2 templating, Alembic schema migrations | Go (Golang), Helm template scripting |
| **Security & Governance** | Non-root container execution (UID 10001), Linux capability drop (`ALL`), `seccompProfile: RuntimeDefault`, Open Policy Agent (OPA/Rego), masked CI variables, `automountServiceAccountToken: false` | TLS certificate termination via Ingress secrets, PostgreSQL row-level locking (`SELECT ... FOR UPDATE`), monotonic fencing tokens | HashiCorp Vault, External Secrets Operator (ESO), Trivy container scanning |
| **Cloud & Infrastructure** | Linux (Ubuntu/Debian systems administration, kernel memory & swap tuning, cgroups v1/v2, `/proc` debugging), WSL2 infrastructure virtualization | Minikube network bridge routing, Ingress SNI reverse proxying | AWS VPC, IAM Roles for Service Accounts (IRSA), Terraform / OpenTofu |

---

## 4. Master Navigation & Documentation Index

Explore detailed documentation across each domain:

* [**Consolidated Portfolio Case Study**](DEVOPS_PORTFOLIO.md): Comprehensive 3-project overview covering engineering decisions and verified results.
* [**System Architecture Reference**](architecture/PROJECT_ARCHITECTURE.md): Technical specifications with complete Mermaid diagrams for all three platforms.
* [**Projects Catalog**](projects/README.md): Detailed breakdowns for [kube-obs](projects/kube-obs/PROJECT_OVERVIEW.md), [git-argo](projects/git-argo/PROJECT_OVERVIEW.md), and [devops-jarvis](projects/devops-jarvis/PROJECT_OVERVIEW.md).
* [**Master Resume Content**](resume/RESUME_CONTENT.md): Ready-to-use resume summaries, bullet points, and narratives tailored for DevOps, Cloud, Platform, and SRE roles.
* [**Interview Preparation Guide**](interview/INTERVIEW_PREPARATION.md): 45 in-depth technical questions and answers across 10 engineering domains.
* [**Troubleshooting Case Studies**](interview/TROUBLESHOOTING_SCENARIOS.md): 7 real-world incident post-mortems with root cause analyses and runbooks.
* [**Verified Screenshot Archives**](evidence/README.md): Catalog of 20 live terminal screenshots validating cluster status, SaaS pipelines, and alerting.
* [**Career Development Roadmap**](roadmap/CAREER_ROADMAP.md): Objective gap analysis, certification goals (CKA, SAA), and future project concepts.
* [**Reusable Project Template**](templates/PROJECT_TEMPLATE.md): Standardized template for authoring future platform documentation.

---

## 5. Contact & Professional Links

* **GitHub**: [github.com/SUPRAVAT001](https://github.com/SUPRAVAT001)
* **GitLab**: [gitlab.com/supravatdash7399](https://gitlab.com/supravatdash7399)
* **Projects**:
  * Kubernetes Observability Platform: [github.com/SUPRAVAT001/kube-obs](https://github.com/SUPRAVAT001/kube-obs)
  * GitOps CI/CD Delivery Platform: [github.com/SUPRAVAT001/git-argo](https://github.com/SUPRAVAT001/git-argo)
  * Hosted GitLab CI/CD Pipeline: [gitlab.com/supravatdash7399/git-argo](https://gitlab.com/supravatdash7399/git-argo)

---

> **Authenticity Note**: All metrics, pipeline IDs, commit SHAs, endpoint responses, and test baselines cited across this portfolio represent actual verified execution on live infrastructure. No production claims, cloud scale, or benchmarks are simulated or exaggerated.
