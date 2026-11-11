# Architecture: GitOps CI/CD Delivery Platform (`git-argo`)

[Project Overview](README.md) · [GitHub Repo](https://github.com/SUPRAVAT001/git-argo) · [GitLab CI/CD](https://gitlab.com/supravatdash7399/git-argo)

---

## End-to-End Delivery Workflow

```mermaid
flowchart TD
    DEV["Developer Push (main)"] --> GL["GitLab Source Repository\nsupravatdash7399/git-argo"]

    subgraph CI["GitLab CI/CD SaaS Pipeline"]
        S1["1. validate\npy_compile + PyYAML + helm lint"]
        S2["2. test\nPytest (6 tests) + JUnit XML"]
        S3["3. build (docker:27-dind TLS)\nMulti-stage image -> image.tar"]
        S4["4. publish\ndocker push :CI_COMMIT_SHORT_SHA & :latest"]
        S5["5. update-gitops (alpine/git)\nsed repository & tag -> git push [skip ci]"]
        S1 --> S2 --> S3 --> S4 --> S5
    end

    GL --> CI
    S4 --> REG["GitLab Container Registry\nregistry.gitlab.com/supravatdash7399/git-argo:9dbdf50d"]
    S5 -->|GITOPS_GITHUB_TOKEN| GH["GitHub GitOps Source of Truth\nSUPRAVAT001/git-argo (helm/gitops-demo/values.yaml)"]

    subgraph K8s["Kubernetes Cluster (Minikube v1.35.1)"]
        ARGO["Argo CD v3.6.1 (argocd namespace)\nApplication CR: targetRevision=main, selfHeal=true"]
        DEPLOY["Deployment: gitops-demo (gitops-demo namespace)\nNon-root UID 10001 | Service ClusterIP :80 -> :8080"]
        ARGO -->|Reconcile Helm Chart| DEPLOY
    end

    GH -->|Poll / Detect Commit| ARGO
    REG -.->|Image Pull| DEPLOY
```

---

## Key Design Decisions

| Component | Decision | Rationale |
| :--- | :--- | :--- |
| **CI vs. GitOps Split** | GitLab runs builds/registry; GitHub holds Helm state | Separates CI execution secrets from cluster deployment history; CI never receives Kubernetes cluster credentials. |
| **Immutable Tagging** | `${CI_COMMIT_SHORT_SHA}` across build & `values.yaml` | Enables exact code-to-pod traceability and deterministic rollback by Git commit revert. |
| **Argo CD Sync Policy** | `selfHeal: true`, `prune: false`, `ApplyOutOfSyncOnly=true` | Automatically reverts manual configuration drift (`kubectl scale`/`edit`) while guarding against accidental deletion of unmanaged objects during local iteration. |
| **Lean Argo CD Profile** | `dex.enabled: false`, `notifications.enabled: false`, `applicationSet.replicas: 0` | Fits Argo CD cleanly alongside the co-located `kube-obs` stack on a memory-constrained Minikube node (`controller` 128Mi req / 256Mi limit). |
| **Version Injection** | `APP_VERSION` injected via Helm `deployment.yaml` from `.Values.image.tag` | Ensures `/version` telemetry dynamically reflects the deployed GitOps SHA tag at runtime. |

---

## Argo CD Reconciliation State Machine

```mermaid
stateDiagram-v2
    [*] --> Synced: Reconciled with GitHub main
    Synced --> OutOfSync: New GitOps commit in values.yaml\nOR manual cluster drift
    OutOfSync --> Syncing: Automated sync / selfHeal=true triggered
    Syncing --> Synced: Helm chart applied & readiness probes pass
    Syncing --> Degraded: Pod failure / probe threshold missed
```

---

## Container & Pod Security Profile

* **Multi-Stage Dockerfile (`python:3.12-slim`)**: Compiles Python dependencies in a `builder` stage and copies only the virtual environment (`/opt/venv`) and source files into the unprivileged `runner` image (`USER 10001:10001`).
* **Pod Security Context**: `runAsNonRoot: true`, `runAsUser: 10001`, `runAsGroup: 10001`, `fsGroup: 10001`, `seccompProfile.type: RuntimeDefault`.
* **Container & SA Hardening**: `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `serviceAccount.automount: false`, and strict resource boundaries (`50m`/`64Mi` requests, `200m`/`128Mi` limits).
