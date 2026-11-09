# Project Overview: GitOps CI/CD Delivery Platform (`git-argo`)

**GitHub Repository**: [github.com/SUPRAVAT001/git-argo](https://github.com/SUPRAVAT001/git-argo)  
**GitLab Repository**: [gitlab.com/supravatdash7399/git-argo](https://gitlab.com/supravatdash7399/git-argo)  
**Status**: Live SaaS Verified (GitLab SaaS Pipeline #3045047835 Passed)  
**Primary Domain**: CI/CD Automation, Container Security, GitOps Continuous Delivery, Kubernetes

---

## 1. Problem Statement

Modern cloud-native engineering frequently suffers from three anti-patterns:
* **The "CI Pushes to Kubernetes" Anti-Pattern**: CI pipelines holding cluster admin credentials and executing imperative `kubectl apply` commands directly. If CI credentials leak, the entire cluster is compromised.
* **Configuration Drift**: Engineers executing ad-hoc `kubectl scale` or `kubectl edit` in production, creating undocumented discrepancies between Git and runtime state.
* **Mutable `latest` Image Tags**: Deploying `latest` tags makes rollback difficult and obscures the exact source code running in production.

The **GitOps CI/CD Delivery Platform** solves this by establishing a strict **separation of concerns**: GitLab handles testing, image compilation, and registry publishing, while GitHub acts as the immutable GitOps source of truth for Argo CD to pull and reconcile declarative Helm manifests into Kubernetes.

---

## 2. Core Delivery Workflow

```
Developer Push (Source Code)
         │
         ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                    GitLab CI/CD Engine                       │
 │  1. validate  ──>  2. test  ──>  3. build  ──>  4. publish   │
 └──────────────────────────────────────┬───────────────────────┘
                                        │
                         Push Image     ▼     GitLab Registry
                     ┌──────────────────────────────────────────┐
                     │  registry.gitlab.com/repo:<commit-sha>   │
                     └──────────────────┬───────────────────────┘
                                        │
                        Stage 5: Update │ GitOps Tag
                                        ▼
 ┌──────────────────────────────────────────────────────────────┐
 │             GitHub Repository (Source of Truth)              │
 │               helm/gitops-demo/values.yaml                   │
 └──────────────────────────────────────┬───────────────────────┘
                                        │
                         Detects Change │ Poll / Webhook
                                        ▼
 ┌──────────────────────────────────────────────────────────────┐
 │             Argo CD Controller (gitops-engine)               │
 │  - Reconciles desired state vs live cluster state            │
 │  - Enforces automated self-healing & drift detection         │
 └──────────────────────────────────────┬───────────────────────┘
                                        │
                         Declarative    ▼     Reconciliation
 ┌──────────────────────────────────────────────────────────────┐
 │               Kubernetes Cluster (Minikube)                  │
 │  - Namespace: gitops-demo                                    │
 │  - Workload: FastAPI Microservice (Non-root, probes, limits) │
 └──────────────────────────────────────────────────────────────┘
```

---

## 3. Technology Stack & Component Inventory

| Layer | Component | Version | Role & Responsibility |
| :--- | :--- | :--- | :--- |
| **CI/CD Platform** | GitLab CI/CD SaaS | Cloud SaaS | Multi-stage pipeline runner, DAG execution, test reporting |
| **Container Registry**| GitLab Registry | Cloud SaaS | Immutable container image storage tagged with git commit SHA |
| **GitOps Controller**| Argo CD | v3.6.1 | Kubernetes-native Git reconciliation, self-healing, drift engine |
| **GitOps Repository**| GitHub | Cloud SaaS | Immutable source of truth for deployment manifests (`values.yaml`)|
| **Package Management**| Helm | v3.22.1 | Workload templating, parameterization, and release management |
| **Containerization** | Docker | v27 CLI / DinD | Multi-stage builds, unprivileged user execution, image packaging |
| **Workload Framework**| FastAPI (Python) | 3.12 | Microservice exposing `/`, `/health`, `/version`, `/metrics` |
| **Testing Harness** | Pytest | v8.4+ | Automated unit tests and JUnit XML report generation |
| **Runtime Cluster** | Kubernetes | v1.35.1 | Minikube single-node container runtime on WSL2 Linux |

---

## 4. Key Architectural Decisions

1. **Immutable Commit SHA Tagging**: Replaced mutable `latest` tags with deterministic git commit SHAs (`${CI_COMMIT_SHORT_SHA}`) across build, publish, and Helm values.
2. **Cluster Pull Instead of CI Push**: The CI pipeline never holds Kubernetes credentials; it only updates GitHub. The cluster pulls declaratively via Argo CD.
3. **Hardened Container Profiles**: Multi-stage builds running as non-root user `appuser` (UID 10001) with capability dropping (`ALL`) and default seccomp profiles.
4. **Offline Local Simulation**: An offline simulation harness (`scripts/local-ci-simulate.sh`) replicates all 5 pipeline stages locally without requiring cloud credentials.

