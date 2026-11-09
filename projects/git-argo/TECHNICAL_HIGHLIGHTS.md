# Technical Highlights: GitOps CI/CD Delivery Platform (`git-argo`)

Real-world troubleshooting cases, automated drift remediation demonstrations, and verified telemetry evidence.

---

## 1. Real-World Pipeline Failures Diagnosed & Resolved

During the hosted integration of the 5-stage GitLab CI/CD pipeline, three technical obstacles were encountered, diagnosed through first principles, and resolved:

### Case 1: YAML Colon-Parser Collision (Pipeline #3044970789)
* **Symptom**: Pipeline definition rejected during syntax parsing before job initiation.
* **Root Cause**: An unquoted echo string (`echo "==> Building Docker image: ${TAG}..."`) contained a colon followed by a space. The GitLab CI YAML parser interpreted this as a nested dictionary mapping key rather than a string literal.
* **Remediation**: Wrapped all script strings containing colons in explicit single quotes (`'echo "==> Building Docker image: ${TAG}..."'`), ensuring the YAML parser treats the entire line as a scalar string. Committed as `1fda3f5`.

### Case 2: `alpine/git` Docker Entrypoint Conflict (Pipeline #3045017523)
* **Symptom**: Stage 5 (`promote-gitops`) terminated immediately with `git: 'sh' is not a git command`.
* **Root Cause**: The official `alpine/git:2.45.2` image configures `ENTRYPOINT ["/usr/bin/git"]`. When GitLab's runner executed its generated shell payload (`sh -c ...`), it passed `sh` as an argument to `git` rather than executing an independent shell.
* **Remediation**: Explicitly overrode the image entrypoint in `.gitlab-ci.yml` using `entrypoint: [""]`, restoring standard shell execution. Committed as `9dbdf50`.

### Case 3: Image Registry Divergence Prevention
* **Symptom**: Potential `ImagePullBackOff` during Kubernetes rollout.
* **Root Cause**: Stage 5 initially used `sed` to update only `image.tag`, leaving `image.repository: gitops-demo` defaulting to DockerHub where the newly built image did not reside.
* **Remediation**: Expanded the `sed` substitution in Stage 5 to update both `repository: ${CI_REGISTRY_IMAGE}` and `tag: ${IMAGE_TAG}`, directing Kubernetes to pull from the verified GitLab Container Registry. Committed as `2376a62`.

---

## 2. Platform Demonstration Scenarios

The platform was subjected to five structured operational scenarios on live infrastructure:

| Scenario | Demonstration Objective | Triggering Action | Argo CD Reaction | Deployed Version |
| :--- | :--- | :--- | :--- | :--- |
| **1. Baseline Sync** | Initial v1.0.0 deployment | Git push to GitHub `main` | Reconciles to `Synced` & `Healthy` | `v1.0.0` (1 replica) |
| **2. Version Promotion** | Upgrade microservice to v2.0.0 | Commit `a702fba` updating `values.yaml` | Zero-downtime rolling update | `v2.0.0` (1 replica) |
| **3. Drift & Self-Healing** | Detect manual out-of-band tampering | `kubectl scale deployment --replicas=3` | Flips to `OutOfSync`, terminates drift pods, restores 1 replica | `v2.0.0` (1 replica) |
| **4. Declarative Rollback** | Clean downgrade without `kubectl` | `git revert a702fba` pushed to GitHub | Detects Git revert commit `9f8c045`, rolls back to v1.0.0 | `v1.0.0` (1 replica) |
| **5. Cloud Hosted CI/CD** | Full cloud delivery: CI -> Registry -> GitOps -> Argo CD | Git push to GitLab `main` | Pipeline #3045047835 passes, promotes commit `a58cf62`, reconciles | `9dbdf50d` (GitLab Registry) |

---

## 3. Visual Demonstration Evidence

Authentic high-resolution terminal screenshots verifying every operational milestone are cataloged in [`evidence/git-argo/`](../../evidence/git-argo):

| Screenshot | Description & Evidence Captured | File Link |
| :--- | :--- | :--- |
| **01** | **Argo CD Initial Sync**: Initial deployment status, Helm release, and single healthy pod. | [`01_argocd_synced_healthy_v1.png`](../../evidence/git-argo/01_argocd_synced_healthy_v1.png) |
| **02** | **Application Endpoints**: Live HTTP response bodies for `/version`, `/health`, and `/metrics`. | [`02_application_v1_endpoint.png`](../../evidence/git-argo/02_application_v1_endpoint.png) |
| **03** | **Version Promotion (v2.0.0)**: Git diff, Argo CD sync to commit `a702fba`, and `/version` returning `v2.0.0`. | [`03_application_v2_endpoint.png`](../../evidence/git-argo/03_application_v2_endpoint.png) |
| **04** | **Argo CD Drift Detection**: Live cluster scaled to 3 replicas, triggering `OutOfSync` status. | [`04_argocd_drift_detected.png`](../../evidence/git-argo/04_argocd_drift_detected.png) |
| **05** | **Argo CD Automated Self-Healing**: Event log capturing automated remediation and termination of drift pods. | [`05_argocd_self_healing.png`](../../evidence/git-argo/05_argocd_self_healing.png) |
| **06** | **Git-Based Declarative Rollback**: Revert commit `9f8c045`, Helm values diff, and live downgrade back to `v1.0.0`. | [`06_gitops_git_rollback.png`](../../evidence/git-argo/06_gitops_git_rollback.png) |
| **07** | **Final Cluster Status**: All workloads healthy across `argocd`, `gitops-demo`, and `observability` namespaces. | [`07_final_kubernetes_status.png`](../../evidence/git-argo/07_final_kubernetes_status.png) |
| **08** | **GitLab Hosted Pipeline Execution**: All 5 stages passed on GitLab SaaS ([Pipeline #3045047835](https://gitlab.com/supravatdash7399/git-argo/-/pipelines/3045047835)). | [`08_gitlab_pipeline_passed.png`](../../evidence/git-argo/08_gitlab_pipeline_passed.png) |
| **09** | **GitLab Container Registry**: Published immutable image (`registry.gitlab.com/supravatdash7399/git-argo:9dbdf50d`). | [`09_gitlab_container_registry.png`](../../evidence/git-argo/09_gitlab_container_registry.png) |
| **10** | **GitHub GitOps Promotion Commit**: Commit `a58cf62` authored by GitLab CI/CD Bot updating `values.yaml`. | [`10_github_gitops_promotion_commit.png`](../../evidence/git-argo/10_github_gitops_promotion_commit.png) |
| **11** | **Argo CD Sync with GitLab Image**: Argo CD reconciled to `a58cf62` showing Synced and Healthy status. | [`11_argocd_synced_healthy_gitlab.png`](../../evidence/git-argo/11_argocd_synced_healthy_gitlab.png) |
| **12** | **Workload Running GitLab Image**: Deployment and pod verified running `registry.gitlab.com/...:9dbdf50d`. | [`12_kubernetes_deployment_published_image.png`](../../evidence/git-argo/12_kubernetes_deployment_published_image.png) |
| **13** | **Application Telemetry**: Live `/version` returning `9dbdf50d` and `/health` returning HTTP 200. | [`13_application_gitlab_version_endpoint.png`](../../evidence/git-argo/13_application_gitlab_version_endpoint.png) |

