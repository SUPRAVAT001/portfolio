# Platform Verification & Operational Evidence Catalog

Authentic, verifiable proof of operational health, test execution, pipeline runs, and failure remediation.

---

## 1. Project 1: Kubernetes Observability Platform (`kube-obs`)

All screenshots below represent live capture of Minikube telemetry during platform verification:

| Evidence Asset | Scope & Captured Metrics | File Reference |
| :--- | :--- | :--- |
| **`cluster-overview.png`** | Cluster-wide executive dashboard: CPU utilization, allocatable memory, pod count per node, and cluster capacity. | [`evidence/kube-obs/cluster-overview.png`](kube-obs/cluster-overview.png) |
| **`node-monitoring.png`** | Deep host telemetry via Node Exporter: kernel load average (1m, 5m, 15m), memory buffer/cache allocation, disk I/O, network packets. | [`evidence/kube-obs/node-monitoring.png`](kube-obs/node-monitoring.png) |
| **`application-monitoring.png`** | Microservice telemetry dashboard: HTTP request throughput (`app_http_requests_total`), p95 latency, response code distribution (2xx, 5xx). | [`evidence/kube-obs/application-monitoring.png`](kube-obs/application-monitoring.png) |
| **`prometheus-targets.png`** | Prometheus Service Discovery console displaying all scrape targets in `UP` state without scrape errors. | [`evidence/kube-obs/prometheus-targets.png`](kube-obs/prometheus-targets.png) |
| **`alert-firing.png`** | Alertmanager console capturing active `Firing` alerts (`KubePodCrashLooping`) during controlled pod failure simulation. | [`evidence/kube-obs/alert-firing.png`](kube-obs/alert-firing.png) |
| **`alert-recovery.png`** | Alertmanager notification state transitioning to `Resolved` following container self-healing and recovery. | [`evidence/kube-obs/alert-recovery.png`](kube-obs/alert-recovery.png) |
| **`validation.png`** | Terminal output of the automated 12-point end-to-end platform validation suite passing 100%. | [`evidence/kube-obs/validation.png`](kube-obs/validation.png) |

---

## 2. Project 2: GitOps CI/CD Delivery Platform (`git-argo`)

Live terminal verification of the 5-stage GitLab CI/CD SaaS pipeline and Argo CD continuous reconciliation:

| Screenshot | Operational Stage | Evidence Captured | File Reference |
| :--- | :--- | :--- | :--- |
| **`01`** | **Initial Baseline** | Argo CD Application reporting `Synced` and `Healthy` on initial release. | [`01_argocd_synced_healthy_v1.png`](git-argo/01_argocd_synced_healthy_v1.png) |
| **`02`** | **Endpoint Verification** | Live curl responses for `/version` (`v1.0.0`), `/health` (`200 OK`), and Prometheus `/metrics`. | [`02_application_v1_endpoint.png`](git-argo/02_application_v1_endpoint.png) |
| **`03`** | **Version Promotion** | Git commit diff and Argo CD synchronizing to commit `a702fba`, `/version` returning `v2.0.0`. | [`03_application_v2_endpoint.png`](git-argo/03_application_v2_endpoint.png) |
| **`04`** | **Drift Detection** | Cluster scaled out-of-band to 3 replicas; Argo CD immediately flags application as `OutOfSync`. | [`04_argocd_drift_detected.png`](git-argo/04_argocd_drift_detected.png) |
| **`05`** | **Automated Self-Healing** | Argo CD event logs confirming automated termination of drift pods and restoration of 1 replica. | [`05_argocd_self_healing.png`](git-argo/05_argocd_self_healing.png) |
| **`06`** | **Git-Driven Rollback** | Clean rollback via `git revert a702fba` (`9f8c045`), zero downtime downgrade to `v1.0.0`. | [`06_gitops_git_rollback.png`](git-argo/06_gitops_git_rollback.png) |
| **`07`** | **Final Cluster Health** | All pods healthy across `argocd`, `gitops-demo`, and `observability` namespaces. | [`07_final_kubernetes_status.png`](git-argo/07_final_kubernetes_status.png) |
| **`08`** | **GitLab Hosted Pipeline** | All 5 stages passed on GitLab SaaS ([Pipeline #3045047835](https://gitlab.com/supravatdash7399/git-argo/-/pipelines/3045047835)). | [`08_gitlab_pipeline_passed.png`](git-argo/08_gitlab_pipeline_passed.png) |
| **`09`** | **Container Registry** | Published image in GitLab Registry (`registry.gitlab.com/supravatdash7399/git-argo:9dbdf50d`). | [`09_gitlab_container_registry.png`](git-argo/09_gitlab_container_registry.png) |
| **`10`** | **GitOps Promotion Commit** | Automated GitHub commit `a58cf62` authored by GitLab CI/CD Bot updating `values.yaml`. | [`10_github_gitops_promotion_commit.png`](git-argo/10_github_gitops_promotion_commit.png) |
| **`11`** | **Argo CD Registry Sync** | Argo CD reconciled to `a58cf62` running the verified GitLab Container Registry image. | [`11_argocd_synced_healthy_gitlab.png`](git-argo/11_argocd_synced_healthy_gitlab.png) |
| **`12`** | **K8s Pod Running Image** | Kubernetes deployment and pod verified running image SHA `9dbdf50d`. | [`12_kubernetes_deployment_published_image.png`](git-argo/12_kubernetes_deployment_published_image.png) |
| **`13`** | **Live Telemetry (GitLab)** | Application `/version` returning `9dbdf50d` and `/health` returning HTTP 200. | [`13_application_gitlab_version_endpoint.png`](git-argo/13_application_gitlab_version_endpoint.png) |

---

## 3. Project 3: Autonomous AI SRE Control Plane (`devops-jarvis`)

Deterministic verification baselines:
* **Active Automated Test Baseline**: **1,419 passed**, 3 skipped, 0 failures.
* **Database Migration State**: PostgreSQL 16 at Alembic revision `c5d6e7f8a9b0 (head)`.
* **Execution Evidence**: Authoritative phase logs documented in [`devops-jarvis/PROJECT_STATUS.md`](../projects/devops-jarvis/IMPLEMENTATION_STATUS.md).

