# Technical Skills Catalog

A detailed breakdown of technical competencies, tools, frameworks, and methodologies.

---

## 1. Cloud Native & Container Technologies

### Containerization & Runtimes
* **Docker / containerd**: Multi-stage unprivileged Dockerfile design, image optimization, layer caching, context reduction via `.dockerignore`, Docker daemon configuration, rootless/unprivileged runtime execution.
* **Docker-in-Docker (DinD)**: Service configuration in CI/CD runners, mTLS socket encryption, certificate distribution across runner jobs.
* **Security & Hardening**: UID/GID 10001 unprivileged non-root execution, Linux capability dropping (`ALL`), `RuntimeDefault` seccomp profiles, non-root filesystem restrictions.

### Kubernetes Orchestration
* **Workload Controllers**: Deployments, StatefulSets (for TSDB storage), DaemonSets (for host agents), Jobs, CronJobs.
* **Networking & Ingress**: ClusterIP and NodePort Services, NGINX Ingress Controller, SNI-based TLS termination with Kubernetes TLS Secrets, DNS resolution inside cluster (`CoreDNS`).
* **Configuration & Storage**: ConfigMaps, Secrets, Persistent Volumes (PV), Persistent Volume Claims (PVC), StorageClasses.
* **Workload Hardening**: `podSecurityContext`, container `securityContext`, dedicated ServiceAccounts with `automountServiceAccountToken: false`.
* **Health Probing**: Decoupled HTTP liveness and readiness probes, initial delays, failure thresholds, period seconds.
* **Lifecycle & Operations**: Zero-downtime rolling updates (`RollingUpdate`), replica scaling, node cordoning, taint and toleration basics, event debugging (`kubectl describe`, `kubectl logs`).

### Packaging & Templating
* **Helm v3**: Chart authoring (`Chart.yaml`, `values.yaml`), template helpers (`_helpers.tpl`), parameter substitution, dependency management, chart validation via `helm lint`, idempotent release management with `helm upgrade --install`.

---

## 2. CI/CD & GitOps Delivery

### Continuous Integration (CI)
* **GitLab CI/CD**: Authored multi-stage `.gitlab-ci.yml` pipelines (`validate`, `test`, `build`, `publish`, `update-gitops`), DAG workflows using `needs`, conditional execution with `rules`, service containers, artifact passing, and cache management.
* **Automated Quality Gates**: Static Python compilation (`py_compile`), structural YAML validation (`yaml.safe_load`), Helm chart linting (`helm lint`), Pytest test execution with JUnit XML reporting (`artifacts:reports:junit`).
* **Container Registry Integration**: Automated image publishing to GitLab Container Registry (`CI_REGISTRY`) using deterministic commit SHA tagging (`${CI_COMMIT_SHORT_SHA}`) and latest reference aliases.

### Continuous Delivery & GitOps (CD)
* **Argo CD**: Installation, declarative configuration via Application Custom Resources (`argocd/application.yaml`), automated sync policies, branch tracking, Git poll interval tuning.
* **Drift Detection & Reconciliation**: Continuous comparison of Git desired state against live Kubernetes API state, automated out-of-band drift detection (`OutOfSync`), and self-healing (`selfHeal: true`).
* **Declarative Rollback**: Zero-downtime rollbacks executed exclusively through Git history (`git revert`) without imperative cluster access.
* **Multi-Repository Architecture**: Strict separation between application source code/CI pipelines (GitLab) and deployment state configuration (GitHub as source of truth).

---

## 3. Observability & Site Reliability Engineering (SRE)

### Metrics Collection & Storage
* **Prometheus Server**: Architecture, time-series database (TSDB) storage engine, retention policies, scrape job configuration (`scrape_configs`), Kubernetes pod annotation discovery (`prometheus.io/scrape`).
* **Exporters & Collectors**: Node Exporter (host CPU, memory, disk, network), Kube-State-Metrics (Kubernetes cluster object states, pod phase transitions, replica counts).
* **PromQL (Prometheus Query Language)**: Metric selection, label matching, rate calculations (`rate()`, `increase()`), vector aggregation (`sum by ()`, `avg by ()`), and threshold alerts.

### Alerting & Incident Management
* **Alertmanager**: Alert routing trees, receiver configurations, grouping (`group_by`), deduplication, inhibition rules, repeat intervals, and HTTP webhook notification dispatch.
* **Alert Rule Engineering**: Authoring Prometheus alerting rules (`PrometheusRule`), multi-stage lifecycle evaluation (Inactive → Pending → Firing → Resolved), crash-loop detection, resource saturation alerts.

### Visualization & Telemetry
* **Grafana**: Dashboard design and provisioning as code, datasource auto-configuration, PromQL panel queries, threshold visualization, `k8s-sidecar` dynamic ConfigMap ingestion.
* **Custom Application Instrumentation**: Exposing cloud-native `/metrics` endpoints in Python/FastAPI using standard Prometheus text exposition format (counters and gauges).

---

## 4. Systems, Scripting & Software Engineering

### Operating Systems & Shell
* **Linux (Ubuntu / Debian)**: Process lifecycle, memory management (RSS, cache, buffers, swap), `/proc` and `/sys` inspection, signals (`SIGTERM`, `SIGKILL`), system services (systemd), user/group permissions.
* **Bash / POSIX Shell**: Automation scripts, CI/CD step handlers, text processing (`sed`, `awk`, `grep`), test harnesses, exit code handling (`set -euo pipefail`).

### Programming & APIs
* **Python 3.12**: Modern async/await programming, type hinting, object-oriented design, custom exception hierarchies, environment configuration.
* **FastAPI**: RESTful API design, request/response validation with Pydantic, custom HTTP middleware for request counters and latency measurement, OpenAPI/Swagger generation.
* **Database & Persistence**: PostgreSQL 16 (schema design, ACID transactions, row-level locking `SELECT ... FOR UPDATE`), SQLAlchemy 2.0 ORM, Alembic schema migrations.
* **Testing & Quality Assurance**: Pytest test suite development, test client execution, fixtures, mock frameworks, JUnit XML artifact generation.

---

## 5. Autonomous Infrastructure & Policy Control (DevOps Jarvis)

### Governed Autonomy Architecture
* **Deterministic Execution Gates**: Two-phase execution contracts where AI models extract intent and propose operations, but mutations are strictly executed by deterministic controllers.
* **Policy Enforcement**: Open Policy Agent (OPA) integration with declarative Rego policies validating plan safety prior to execution.
* **Risk Evaluation**: Pre-execution risk assessment engine evaluating command impact, blast radius, target criticality, and environment context.
* **Simulation & Approval**: Pre-execution dry-run simulation verifying state preconditions and triggering human-in-the-loop approval workflows for high-risk mutations.
* **Distributed Concurrency**: PostgreSQL row-level lease locking, monotonic fencing tokens preventing split-brain execution, and authoritative cluster readbacks during self-healing reconciliation loops.

