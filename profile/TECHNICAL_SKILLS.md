# Technical Skills

Skills are classified by verifiable implementation depth across my three engineering platforms rather than generalized tool lists.

---

## Implemented & Verified in Running Systems

| Category | Technologies & Patterns | Verification Evidence |
| :--- | :--- | :--- |
| **Containers & Orchestration** | Kubernetes (Deployments, StatefulSets, DaemonSets, Services, Ingress, ConfigMaps, Secrets, PVCs, Probes, Resource Limits), Helm v3, Docker (multi-stage builds, `.dockerignore`), Minikube | Authored Helm chart (`gitops-demo`); deployed `kube-prometheus-stack` and Argo CD (`dex`/`notifications` disabled for resource efficiency) on Kubernetes v1.35.1. |
| **CI/CD & GitOps** | GitLab CI/CD (`.gitlab-ci.yml`, 5-stage pipeline, JUnit XML artifacts, `docker:27-dind` over mTLS), GitLab Container Registry, GitHub GitOps promotion, Argo CD (`selfHeal: true`, drift remediation, `git revert` rollback) | Executed hosted GitLab SaaS Pipeline `#3045047835` pushing immutable SHA image `9dbdf50d`; verified Argo CD drift detection and rollback. |
| **Monitoring & Observability** | Prometheus Operator (`ServiceMonitor`, `PrometheusRule`), Prometheus TSDB, Alertmanager (webhook routing), Grafana (`k8s-sidecar` JSON dashboards), Node Exporter, Kube-State-Metrics, PromQL | 16/16 scrape targets active at 10s interval; 136 alert rules evaluated; verified `FIRING` and `RESOLVED` webhook cycle (`kube-obs`) + live canary metrics (`devops-jarvis`). |
| **Security & Policy Governance** | Container hardening (`runAsNonRoot: true`, `UID 10001`, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`, `automount: false`), Open Policy Agent (`openpolicyagent/opa` + Rego), NGINX Ingress TLS Secrets, masked CI tokens (`GITOPS_GITHUB_TOKEN`) | Passed Kubernetes Restricted Pod Security Standards check in `kube-obs` and `git-argo`; enforced `m1.rego` gate via OPA container in `devops-jarvis`. |
| **Backend, APIs & State** | Python (3.12 / 3.14), FastAPI, Uvicorn, stdlib `http.server` + `prometheus_client`, Pydantic, SQLAlchemy 2.0, Alembic, PostgreSQL 17 (`SELECT ... FOR UPDATE` row-level locks, monotonic fencing tokens), Pytest | Built telemetry microservice (`git-argo`), native `/metrics` + alert webhook app (`kube-obs`), and 1,419-test control plane (`devops-jarvis`). |
| **Programming & Scripting** | Python, Bash / POSIX Shell, SQL, Rego, YAML, Jinja2 / Helm Go Templates | Authored CI simulation, TLS setup, deployment, and 12-point validation scripts (`setup.sh`, `deploy.sh`, `validate.sh`, `local-ci-simulate.sh`). |
| **Linux & Systems** | Ubuntu Linux, WSL2 memory/swap tuning (`.wslconfig`), cgroups/namespaces resource isolation, `kubectl` diagnostics, `curl`/`openssl` TLS inspection | Resolved WSL2 swap exhaustion cluster outage (`NotReady`) without losing cluster PVCs or stateful workloads. |

---

## Conceptual & Roadmap Scope

These areas are understood conceptually or partially scaffolded (for example, cloud provider abstractions inside `devops-jarvis`), but are **not claimed as production implementations**:

* **Public Cloud & IaC**: AWS (IAM, VPC, EKS), GCP (GKE), Azure (AKS), and Terraform / OpenTofu provisioning.
* **Advanced Cluster Tooling**: `cert-manager` (ACME), External Secrets Operator / HashiCorp Vault, Prometheus Thanos / Mimir long-term storage, and distributed tracing (OpenTelemetry).
