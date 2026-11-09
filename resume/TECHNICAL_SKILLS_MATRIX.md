# Technical Skills Matrix

Skills mapped to verified implementation evidence from both portfolio projects.

**Legend:**
- ✅ **Implemented & Verified** — Built, deployed, debugged, and confirmed working
- 🟡 **Used** — Applied in project context, working knowledge
- 📖 **Familiar** — Conceptual understanding, not yet implemented in a project

---

## Container Technology

| Skill | Level | Evidence |
|-------|-------|----------|
| Docker multi-stage builds | ✅ Implemented & Verified | `git-argo` Dockerfile: builder stage (pip install) + runtime stage (non-root copy). Builds successfully in both local simulation and GitLab DinD |
| Docker-in-Docker (DinD) | ✅ Implemented & Verified | `.gitlab-ci.yml` Stages 3–4: `docker:27-dind` service, TLS certs via `DOCKER_TLS_CERTDIR`, port 2376. Debugged entrypoint conflict in `alpine/git` |
| Non-root container user | ✅ Implemented & Verified | UID 10001 set in Dockerfile `USER` directive and Kubernetes `runAsUser: 10001`, `runAsNonRoot: true` |
| Linux capability dropping | ✅ Implemented & Verified | `capabilities.drop: [ALL]` in Helm securityContext, `seccompProfile: RuntimeDefault` |
| `.dockerignore` hygiene | ✅ Implemented & Verified | Excludes `.git`, `__pycache__`, `*.pyc`, `.env`, venv, test artifacts |
| Container image tagging strategy | ✅ Implemented & Verified | Immutable `${CI_COMMIT_SHORT_SHA}` tags; `latest` alias published separately; strategy documented |
| Docker registry authentication | ✅ Implemented & Verified | `docker login` with `CI_REGISTRY_USER` / `CI_REGISTRY_PASSWORD` in GitLab CI; `imagePullSecret` for Kubernetes |
| Dockerfile `EXPOSE` / port mapping | ✅ Implemented & Verified | `EXPOSE 8080` in Dockerfile; `targetPort: 8080` in Kubernetes Service |
| `docker save` / `docker load` | ✅ Implemented & Verified | Used between build and publish stages to pass the image as a CI artifact |
| Rootless Docker / Kaniko | 📖 Familiar | Understand the concept and when to use vs. DinD; not yet implemented |

---

## Container Orchestration (Kubernetes)

| Skill | Level | Evidence |
|-------|-------|----------|
| Deployment management | ✅ Implemented & Verified | Deployed and managed Deployments in `gitops-demo`, `observability`, `argocd` namespaces |
| StatefulSet operation | 🟡 Used | Prometheus and Alertmanager run as StatefulSets in `kube-obs` |
| DaemonSet operation | 🟡 Used | Node Exporter runs as a DaemonSet in `kube-obs` |
| Service types (ClusterIP, NodePort) | ✅ Implemented & Verified | ClusterIP for `gitops-demo`; NodePort / `minikube service` for access; understood LoadBalancer limitations in Minikube |
| Namespace isolation | ✅ Implemented & Verified | 3 application namespaces + system namespaces; namespace-scoped `kubectl` commands throughout |
| Liveness & readiness probes | ✅ Implemented & Verified | Both configured in Helm chart on `/health`; different `initialDelaySeconds` and `failureThreshold` values justified |
| Resource requests & limits | ✅ Implemented & Verified | `requests: 50m/64Mi`, `limits: 200m/128Mi` for `gitops-demo`; tuned for multi-workload constrained node |
| Pod security context | ✅ Implemented & Verified | `runAsNonRoot`, `runAsUser`, `fsGroup`, `seccompProfile`, `capabilities.drop: [ALL]` |
| Service Account configuration | ✅ Implemented & Verified | Dedicated SA per app, `automountServiceAccountToken: false` |
| ConfigMap for env vars | ✅ Implemented & Verified | Helm-generated ConfigMap feeding `APP_NAME`, `APP_ENV`, `GITOPS_TOOL` via `envFrom` |
| Persistent Volumes / PVCs | 🟡 Used | Prometheus and Grafana use PVCs for data persistence in `kube-obs` |
| Rolling update strategy | ✅ Implemented & Verified | Default `RollingUpdate` verified during version promotions and rollbacks |
| `kubectl` proficiency | ✅ Implemented & Verified | `get`, `describe`, `logs`, `port-forward`, `scale`, `exec`, `apply`, `delete`, `top`, `rollout` |
| NGINX Ingress Controller | ✅ Implemented & Verified | Deployed in `kube-obs` for TLS-terminated access to Grafana |
| Kubernetes RBAC | 📖 Familiar | Understand ClusterRole, Role, RoleBinding, ClusterRoleBinding; not authored custom RBAC policies |
| Network Policies | 📖 Familiar | Understand concept; not implemented in projects |
| Horizontal Pod Autoscaler | 📖 Familiar | Understand HPA based on CPU/memory metrics; not implemented |
| Multi-node cluster operation | 📖 Familiar | All work on single-node Minikube; understand multi-node scheduling concepts |

---

## CI/CD

| Skill | Level | Evidence |
|-------|-------|----------|
| GitLab CI/CD pipeline authoring | ✅ Implemented & Verified | 162-line `.gitlab-ci.yml`, 5 stages, `rules`, `needs`, `artifacts`, `services`, custom image overrides |
| GitLab Container Registry | ✅ Implemented & Verified | Published `registry.gitlab.com/supravatdash7399/git-argo:9dbdf50d` via CI |
| GitLab CI/CD variables (masked/protected) | ✅ Implemented & Verified | `GITOPS_GITHUB_TOKEN` configured as Protected, Masked, Hidden in GitLab Settings |
| Pipeline YAML debugging | ✅ Implemented & Verified | Diagnosed and fixed 3 real pipeline failures (YAML colon parser, alpine/git entrypoint, wrong repository in sed) |
| JUnit XML test reporting | ✅ Implemented & Verified | `pytest --junitxml=junit-report.xml` with `artifacts.reports.junit` in GitLab |
| Docker-in-Docker pipeline | ✅ Implemented & Verified | Stages 3–4 with TLS-enabled DinD service |
| Local CI simulation | ✅ Implemented & Verified | `scripts/local-ci-simulate.sh` replicates all 5 stages locally without GitLab |
| GitHub Actions | 📖 Familiar | Understand workflow syntax, actions marketplace, secrets; not yet authored a full workflow |
| Jenkins | 📖 Familiar | Aware of Declarative Pipeline syntax, Jenkinsfile; no hands-on project implementation |
| Cross-platform token security | ✅ Implemented & Verified | GitHub PAT for GitLab→GitHub push; SSH keys for both remotes; PAT never logged |

---

## GitOps & Delivery

| Skill | Level | Evidence |
|-------|-------|----------|
| Argo CD installation | ✅ Implemented & Verified | Installed in `argocd` namespace on constrained node; Dex disabled; lean resource configuration |
| Argo CD Application CR authoring | ✅ Implemented & Verified | `argocd/application.yaml` with Helm source, automated sync, selfHeal, prune |
| GitOps reconciliation workflow | ✅ Implemented & Verified | Full end-to-end: Git commit → Argo CD detects → applies Helm → pod updated |
| Drift detection | ✅ Implemented & Verified | Manual `kubectl scale` to 3 replicas → OutOfSync detected → self-healed within seconds |
| Declarative rollback via Git revert | ✅ Implemented & Verified | `git revert a702fba` → Argo CD rolled back v2.0.0 → v1.0.0 |
| Separation of CI and CD repositories | ✅ Implemented & Verified | GitLab (CI/CD) ↔ GitHub (deployment config) — deliberate architecture decision |
| Argo CD CLI (`argocd`) | 🟡 Used | `argocd app get`, `app sync`, `app history`, port-forward access |
| Argo CD Image Updater | 📖 Familiar | Understand it automates registry polling and values.yaml updates; not yet implemented |
| Flux CD | 📖 Familiar | Aware of alternative GitOps controller; understands differences vs. Argo CD |

---

## Observability

| Skill | Level | Evidence |
|-------|-------|----------|
| Prometheus scrape configuration | ✅ Implemented & Verified | `scrape_configs` targeting Node Exporter, kube-state-metrics, FastAPI /metrics via pod annotations |
| Prometheus alerting rules | ✅ Implemented & Verified | Alert rules for crash-loop detection, pod unavailability, high memory; `pending` → `firing` validated |
| PromQL | 🟡 Used | `rate()`, `increase()`, `up`, label matchers; used in Grafana dashboard queries and alert expressions |
| Alertmanager routing configuration | ✅ Implemented & Verified | Routing tree with label matchers; webhook receiver configured and tested |
| Grafana dashboard creation | ✅ Implemented & Verified | Kubernetes node, pod resource, and application metric dashboards built in `kube-obs` |
| Custom Prometheus metrics (Python) | ✅ Implemented & Verified | `app_uptime_seconds`, `app_info`, `app_http_requests_total` in Prometheus text format via FastAPI `/metrics` |
| kube-state-metrics | 🟡 Used | Deployed and scraped in `kube-obs`; exposes K8s object state to Prometheus |
| Node Exporter | 🟡 Used | Deployed as DaemonSet; host-level CPU/memory/disk metrics |
| OpenTelemetry | 📖 Familiar | Understand OTLP, traces, spans, context propagation; not yet implemented in a project |
| Log aggregation (EFK/Loki) | 📖 Familiar | Understand architecture; no hands-on project implementation |

---

## Infrastructure as Code / Configuration Management

| Skill | Level | Evidence |
|-------|-------|----------|
| Helm chart authoring | ✅ Implemented & Verified | Full chart: `Chart.yaml`, `values.yaml`, 6 templates (Deployment, Service, ConfigMap, SA, Ingress, helpers) |
| Helm `values.yaml` parameterization | ✅ Implemented & Verified | Image tag, replicas, resources, probes, security context all configurable |
| `helm lint` | ✅ Implemented & Verified | Run as Stage 1 of CI pipeline |
| `helm upgrade --install` | ✅ Implemented & Verified | Idempotent deploy command used in local simulation and manual operations |
| Terraform | 📖 Familiar | Understand HCL syntax, state management, providers, plan/apply workflow; no hands-on project |
| Ansible | 📖 Familiar | Aware of playbook/role structure; no hands-on project |
| Pulumi | 📖 Familiar | Aware of concept; not implemented |

---

## Languages & Frameworks

| Skill | Level | Evidence |
|-------|-------|----------|
| Python 3.12 | ✅ Implemented & Verified | FastAPI application, middleware, async handlers, os.getenv, time module, type hints |
| FastAPI | ✅ Implemented & Verified | 4 endpoints (`/`, `/health`, `/version`, `/metrics`), HTML/JSON response negotiation, middleware |
| Pytest | ✅ Implemented & Verified | 6-case test suite, `TestClient`, fixtures, JUnit XML output |
| Bash scripting | ✅ Implemented & Verified | `local-ci-simulate.sh` (5-stage simulation), GitLab CI `script` blocks, `sed` patterns |
| YAML authoring | ✅ Implemented & Verified | Kubernetes manifests, Helm templates, Argo CD CRs, GitLab CI pipeline |
| Go | 📖 Familiar | Can read Go code; understand Helm template syntax (Go templating); no authoring experience |
| JavaScript / TypeScript | 📖 Familiar | Basic reading ability; not relevant to current DevOps focus |

---

## Autonomous Systems, Governance & Distributed State (DevOps Jarvis)

| Skill | Level | Evidence |
|-------|-------|----------|
| Deterministic execution choke points | ✅ Implemented & Verified | `ExecutionController` in `devops-jarvis`: enforces mandatory policy, risk, simulation, and approval gates before any cluster mutation |
| Open Policy Agent (OPA) / Rego | ✅ Implemented & Verified | Declarative Rego policy evaluation rejecting unsafe infrastructure plans; verified across automated test suite |
| Dynamic risk evaluation & blast radius | ✅ Implemented & Verified | `RiskEngine`: algorithmic blast-radius scoring evaluating replica counts, dependency depth, and environment tiers |
| Two-phase dry-run simulation | ✅ Implemented & Verified | `SimulationService`: cluster state readbacks verifying preconditions prior to execution commitment |
| Distributed lease locking | ✅ Implemented & Verified | PostgreSQL 16 row-level locks (`SELECT ... FOR UPDATE`) with bounded TTLs preventing concurrent mutation collisions |
| Monotonic fencing tokens | ✅ Implemented & Verified | Monotonically incrementing fencing tokens that reject stale/zombie worker transactions |
| Metric-driven progressive delivery | ✅ Implemented & Verified | `CanaryEvaluator`: autonomous multi-stage traffic shifting (10% → 25% → 50% → 100%) against live Prometheus metrics |
| Epistemic safety invariants | ✅ Implemented & Verified | Strict `UNKNOWN != SAFE` and `STALE != FRESH` error-budget halts during automated rollouts |
| Self-healing reconciliation loops | ✅ Implemented & Verified | Startup recovery and periodic ticks performing authoritative cluster readbacks to resume interrupted workflows |
| Alembic database schema migrations | ✅ Implemented & Verified | Schema versioning at revision `c5d6e7f8a9b0 (head)` maintaining relational task, lease, and telemetry state |

---

## Security

| Skill | Level | Evidence |
|-------|-------|----------|
| Non-root container execution | ✅ Implemented & Verified | UID 10001 in Dockerfile + Kubernetes podSecurityContext |
| Linux capability management | ✅ Implemented & Verified | `capabilities.drop: [ALL]` in securityContext |
| seccomp profiles | ✅ Implemented & Verified | `seccompProfile: RuntimeDefault` in podSecurityContext |
| CI secret management | ✅ Implemented & Verified | GitLab masked/protected variables; token never echoed in logs |
| `.gitignore` credential hygiene | ✅ Implemented & Verified | `.env`, `*.pem`, `kubeconfig`, SSH keys excluded |
| `serviceAccountToken` least-privilege | ✅ Implemented & Verified | `automountServiceAccountToken: false` on application SA |
| TLS certificate management | 🟡 Used | TLS configured in `kube-obs` NGINX Ingress; self-signed cert |
| Secrets encryption at rest (Sealed Secrets / ESO) | 📖 Familiar | Understand the problem; not yet implemented |
| Pod Security Admission / Standards | 📖 Familiar | Aware of `restricted` / `baseline` / `privileged` profiles; not yet enforced at namespace level |
| Container image scanning | 📖 Familiar | Aware of Trivy, Grype; not yet integrated into CI pipeline |

---

## Cloud Platforms

| Skill | Level | Evidence |
|-------|-------|----------|
| Local Kubernetes (Minikube) | ✅ Implemented & Verified | WSL2 + Docker driver, profile management, `minikube image load`, `minikube service` |
| AWS (EKS, ECR, IAM) | 📖 Familiar | Understand EKS architecture, IAM roles for service accounts (IRSA), ECR; no hands-on project |
| GCP (GKE, Artifact Registry) | 📖 Familiar | Aware of GKE managed control plane, Workload Identity; no hands-on project |
| Azure (AKS) | 📖 Familiar | Aware of AKS architecture; no hands-on project |

---

## Career Gap Analysis

Areas to build next for target roles (DevOps Engineer / Platform Engineer / SRE):

| Gap | Priority | Suggested Next Step |
|-----|----------|-------------------|
| Cloud provider experience (AWS/GCP/Azure) | 🔴 High | Deploy `git-argo` to EKS or GKE; use managed registry (ECR/Artifact Registry) |
| Terraform | 🔴 High | Provision the EKS cluster or VPC with Terraform; demonstrates IaC in cloud context |
| GitHub Actions | 🟡 Medium | Port `.gitlab-ci.yml` to GitHub Actions workflow for the same repo |
| Secrets management (Vault / ESO) | 🟡 Medium | Replace ConfigMap env vars with External Secrets Operator pulling from Vault |
| Container image scanning (Trivy) | 🟡 Medium | Add Trivy scan stage to CI pipeline — low effort, high signal |
| Network Policies | 🟡 Medium | Author deny-all + allow rules for `gitops-demo` namespace |
| Cloud provider certification | 🟡 Medium | CKA (Certified Kubernetes Administrator) or AWS Solutions Architect Associate |
| Production traffic / real users | ⚪ Context | Minikube demo acknowledged as local; join a team for production exposure |
| HA / multi-node Kubernetes | ⚪ Context | Understand concepts; production Kubernetes experience addresses this |

---

> **Note**: All "Implemented & Verified" ratings reflect work demonstrated in the `kube-obs` and `git-argo` projects with actual execution evidence (pipeline runs, endpoint responses, screenshots). No self-assessments are inflated to include cloud or production environments not yet worked in.

