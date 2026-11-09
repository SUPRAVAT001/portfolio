# Project Architecture Reference

Detailed technical architecture for both DevOps portfolio projects.

---

## Project 1: Kubernetes Observability Platform (`kube-obs`)

### Overview

A full-stack Kubernetes observability platform implementing the standard cloud-native monitoring pattern: metrics collection (Prometheus), alerting (Alertmanager), and visualization (Grafana), deployed on a self-managed Minikube cluster via Helm.

### Component Architecture

```mermaid
flowchart TD
    subgraph Kubernetes["Kubernetes Cluster (Minikube)"]
        subgraph obs["Namespace: observability"]
            NE["Node Exporter\n(DaemonSet)\nHost OS metrics"]
            KSM["kube-state-metrics\nK8s object state"]
            PROM["Prometheus\nScrape → TSDB\nAlert evaluation"]
            AM["Alertmanager\nAlert routing\nNotification dispatch"]
            GF["Grafana\nDashboard rendering\nMetric queries"]
            APP["FastAPI Demo App\n/metrics endpoint\nInstrumented workload"]
        end
        subgraph ingress["Ingress Layer"]
            NGINX["NGINX Ingress Controller\nTLS termination\nHTTP → HTTPS"]
        end
    end

    USER["Browser / curl"] -->|HTTPS| NGINX
    NGINX -->|/grafana| GF
    NGINX -->|/app| APP

    PROM -->|Scrape :9100| NE
    PROM -->|Scrape :8080| KSM
    PROM -->|Scrape :8080/metrics| APP
    PROM -->|Fire alerts| AM

    AM -->|HTTP POST| WEBHOOK["Alert Webhook\nReceiver"]
    GF -->|PromQL queries| PROM

    style Kubernetes fill:#1a1a2e,color:#e0e0ff
    style obs fill:#16213e,color:#e0e0ff
    style ingress fill:#0f3460,color:#e0e0ff
```

### Data Flow: Metrics Collection to Alert

```mermaid
sequenceDiagram
    participant NE as Node Exporter
    participant App as FastAPI /metrics
    participant Prom as Prometheus
    participant AM as Alertmanager
    participant GF as Grafana
    participant WH as Webhook Receiver

    loop Every scrape_interval (15s default)
        Prom->>NE: GET /metrics
        NE-->>Prom: node_cpu, node_memory, node_disk...
        Prom->>App: GET /metrics
        App-->>Prom: app_uptime_seconds, app_http_requests_total...
    end

    loop Every evaluation_interval
        Prom->>Prom: Evaluate alert rules
        Note over Prom: Rule: pod crash > threshold
        Prom->>AM: Fire alert (FIRING)
        AM->>WH: HTTP POST alert payload
    end

    GF->>Prom: PromQL: rate(app_http_requests_total[5m])
    Prom-->>GF: Time-series data points
    GF->>GF: Render dashboard panel
```

### Key Technical Decisions (kube-obs)

| Decision | Rationale |
|----------|-----------|
| Prometheus Operator vs. raw Prometheus | Raw Prometheus used for direct control over `scrape_configs` and to avoid Operator CRD complexity on a single-node Minikube cluster |
| Helm chart packaging | All components packaged with Helm to enable reproducible `values.yaml`-driven configuration |
| Pod annotation-based discovery | `prometheus.io/scrape: "true"` on FastAPI pods enables automatic Prometheus target discovery without static config |
| NGINX Ingress with TLS | Demonstrates TLS termination in Kubernetes — a production requirement that is frequently a gap in demo setups |
| Controlled failure scenarios | Intentionally terminating pods to validate the full alert pipeline: Kubernetes event → Prometheus rule evaluation → Alertmanager → webhook |

### Resource Architecture

| Component | Type | Resource Profile |
|-----------|------|-----------------|
| Prometheus | StatefulSet (PVC) | High: stores TSDB metrics data |
| Alertmanager | Deployment | Low: stateless alert router |
| Grafana | Deployment (PVC) | Medium: dashboard rendering |
| kube-state-metrics | Deployment | Low: lightweight K8s API proxy |
| Node Exporter | DaemonSet | Low: host-level metric exposure |
| FastAPI Demo | Deployment | Very Low: instrumented demo workload |

---

## Project 2: GitOps CI/CD Delivery Platform (`git-argo`)

### Overview

A production-pattern GitOps delivery platform implementing strict separation between CI/CD concerns (GitLab) and deployment configuration concerns (GitHub + Argo CD). The core principle: the Kubernetes cluster state is always derived from Git — never from manual commands.

### Full System Architecture

```mermaid
flowchart TD
    DEV["Developer\ngit push"] -->|Source code| GL_REPO["GitLab Repository\nsupravatdash7399/git-argo"]

    subgraph GitLabCI["GitLab CI/CD Engine (SaaS)"]
        S1["Stage 1: validate\npy_compile + YAML + helm lint"]
        S2["Stage 2: test\nPytest + JUnit XML"]
        S3["Stage 3: build\nDocker DinD multi-stage build\nTag: CI_COMMIT_SHORT_SHA"]
        S4["Stage 4: publish\ndocker push → GitLab Registry"]
        S5["Stage 5: update-gitops\nClone GitHub → sed values.yaml\ngit commit [skip ci] → push"]
        S1 --> S2 --> S3 --> S4 --> S5
    end

    GL_REPO -->|Triggers pipeline| GitLabCI

    S4 -->|Push image| REGISTRY["GitLab Container Registry\nregistry.gitlab.com/supravatdash7399/git-argo\n:9dbdf50d (commit SHA)"]

    S5 -->|GITOPS_GITHUB_TOKEN\nHTTPS push| GH_REPO["GitHub Repository\nSUPRAVAT001/git-argo\n(Source of Truth)\nhelm/gitops-demo/values.yaml\nimage.tag: 9dbdf50d"]

    subgraph ArgoCD["Argo CD (argocd namespace)"]
        CTRL["Application Controller\nPolls GitHub every 3min\nDesired state ≠ Live state → Sync\nselfHeal: true"]
    end

    GH_REPO -->|Git poll / detect change| ArgoCD

    subgraph K8s["Kubernetes (Minikube, gitops-demo namespace)"]
        DEPLOY["Deployment: gitops-demo\n1 replica\nrunAsUser: 10001\ncapabilities drop: ALL"]
        POD["Pod: gitops-demo-xxx\nImage: registry.gitlab.com/.../git-argo:9dbdf50d\nProbes: /health (liveness + readiness)"]
        SVC["Service: ClusterIP :80 → :8080"]
        DEPLOY --> POD
        SVC --> POD
    end

    ArgoCD -->|kubectl apply Helm templates| K8s
    POD -->|/version /health /metrics| USER2["curl / browser"]

    style GitLabCI fill:#1a1a2e,color:#e0e0ff
    style ArgoCD fill:#16213e,color:#e0e0ff
    style K8s fill:#0f3460,color:#e0e0ff
```

### GitLab CI/CD Pipeline Architecture

```mermaid
flowchart LR
    subgraph S1["Stage 1: validate"]
        V1["python3 -m py_compile\napp/main.py"]
        V2["python3 yaml.safe_load\n*.yaml files"]
        V3["helm lint\nhelm/gitops-demo"]
        V1 --> V2 --> V3
    end

    subgraph S2["Stage 2: test"]
        T1["pip install -r\nrequirements-dev.txt"]
        T2["pytest app/tests -v\n--junitxml=junit-report.xml"]
        T3["Artifact upload:\njunit-report.xml (7 days)"]
        T1 --> T2 --> T3
    end

    subgraph S3["Stage 3: build"]
        B1["docker build\n--build-arg APP_VERSION=SHA\n-f docker/Dockerfile"]
        B2["docker save → image.tar\n(artifact 2h TTL)"]
        B1 --> B2
    end

    subgraph S4["Stage 4: publish"]
        P1["docker load image.tar"]
        P2["docker login CI_REGISTRY"]
        P3["docker push :SHA\ndocker push :latest"]
        P1 --> P2 --> P3
    end

    subgraph S5["Stage 5: update-gitops"]
        G1["git clone GitHub\n(GITOPS_GITHUB_TOKEN)"]
        G2["sed repository: CI_REGISTRY_IMAGE\nsed tag: SHA"]
        G3["git diff check\ngit commit [skip ci]"]
        G4["git push origin main"]
        G1 --> G2 --> G3 --> G4
    end

    S1 --> S2 --> S3 --> S4 --> S5
```

### Argo CD Reconciliation Loop

```mermaid
stateDiagram-v2
    [*] --> Synced: Initial deployment / sync complete

    Synced --> OutOfSync: Git commit detected\n(values.yaml tag changed)\nOR manual drift detected\n(kubectl scale replicas≠1)

    OutOfSync --> Syncing: selfHeal=true triggers\nautomatic reconciliation

    Syncing --> Synced: kubectl apply Helm templates\nRolling update completes\nAll pods Healthy

    Syncing --> Degraded: Pod fails to start\n(ImagePullBackOff / CrashLoop)

    Degraded --> Syncing: Manual intervention\nor image fix pushed to Git
```

### Container Security Architecture

```
Docker Multi-Stage Build (docker/Dockerfile)
├── Stage 1: builder (python:3.12-slim)
│   └── pip install --no-cache-dir → /app/wheels
│
└── Stage 2: runtime (python:3.12-slim)
    ├── COPY --chown=10001:10001 from builder
    ├── USER 10001 (non-root appuser)
    └── EXPOSE 8080

Kubernetes Pod Security (values.yaml)
├── podSecurityContext:
│   ├── runAsNonRoot: true
│   ├── runAsUser: 10001
│   ├── runAsGroup: 10001
│   ├── fsGroup: 10001
│   └── seccompProfile: RuntimeDefault
│
└── containerSecurityContext:
    ├── allowPrivilegeEscalation: false
    ├── readOnlyRootFilesystem: false
    └── capabilities.drop: [ALL]
```

### Application API Architecture

```
FastAPI Application (app/main.py)
│
├── Middleware: track_metrics()
│   └── Intercepts every request → increments REQUEST_COUNTS[method:path:status]
│
├── GET /                 → HTMLResponse (landing page) or JSONResponse (Accept: application/json)
│   └── Displays: APP_NAME, APP_VERSION, APP_ENV, GIT_COMMIT, GITOPS_TOOL, uptime
│
├── GET /health           → {"status":"healthy","timestamp":...,"version":...,"environment":...}
│   └── Used by: Kubernetes liveness probe (period: 10s) + readiness probe (period: 5s)
│
├── GET /version          → {"version":...,"environment":...,"git_commit":...,"gitops_managed":true}
│   └── Version injected via: ENV var APP_VERSION from Helm ConfigMap → Container env
│
└── GET /metrics          → Prometheus text format (Content-Type: text/plain; version=0.0.4)
    └── Exposes: app_uptime_seconds (gauge), app_info (gauge), app_http_requests_total (counter)

Configuration injection chain:
  Git commit SHA (CI_COMMIT_SHORT_SHA)
    → values.yaml image.tag
      → Argo CD applies Helm
        → ConfigMap APP_VERSION env var
          → Container environment
            → FastAPI os.getenv("APP_VERSION")
              → /version response body
```

### Infrastructure: Helm Chart Structure

```
helm/gitops-demo/
├── Chart.yaml                   # Chart metadata, version: 0.1.0, appVersion: 1.0.0
├── values.yaml                  # Configurable defaults (image, replicas, resources, probes)
└── templates/
    ├── _helpers.tpl             # name/label helper functions
    ├── deployment.yaml          # Deployment: securityContext, probes, envFrom ConfigMap
    ├── service.yaml             # ClusterIP: port 80 → targetPort 8080
    ├── configmap.yaml           # APP_NAME, APP_ENV, GITOPS_TOOL env vars
    ├── serviceaccount.yaml      # Dedicated SA, automountServiceAccountToken: false
    └── ingress.yaml             # Optional NGINX ingress (enabled: false by default)

Resource configuration (values.yaml):
  requests: cpu=50m,  memory=64Mi
  limits:   cpu=200m, memory=128Mi
```

### Namespace and Cluster Layout

```
Minikube Cluster (Kubernetes v1.35.1, single node, WSL2 Ubuntu)
│
├── Namespace: argocd
│   ├── argocd-server              (Argo CD API server + UI)
│   ├── argocd-application-controller (reconciliation loop)
│   ├── argocd-repo-server         (Git repository operations)
│   └── argocd-redis               (cache)
│
├── Namespace: gitops-demo
│   ├── Deployment: gitops-demo    (FastAPI microservice)
│   └── Service: gitops-demo       (ClusterIP)
│
├── Namespace: observability (kube-obs)
│   ├── prometheus-0               (StatefulSet)
│   ├── alertmanager-0             (StatefulSet)
│   ├── grafana-xxx                (Deployment)
│   ├── kube-state-metrics-xxx     (Deployment)
│   ├── node-exporter-xxx          (DaemonSet)
│   └── observability-demo-xxx     (FastAPI, 2 replicas)
│
└── Namespace: default
    └── (Jarvis staging: docker-compose, not K8s)
```

---

## Project 3: Autonomous AI SRE Control Plane (`devops-jarvis`)

### Overview

An autonomous AI DevOps and SRE control plane operating production cloud-native infrastructure through natural language while enforcing deterministic safety gates, risk evaluation, policy compliance, two-phase simulation, and human approval workflows.

### 5-Zone Bounded Autonomy Architecture

```mermaid
flowchart TD
    subgraph Zone1["Zone 1: Cognitive & Intent Engine (Stochastic)"]
        LLM["Large Language Model / Intent Parser"]
        CONTEXT["Engineering Context Graph\n(Topology & Dependency Injector)"]
        PLAN["Structured Action Schema\n(Declarative Intent Payload)"]
        LLM --> CONTEXT --> PLAN
    end

    subgraph Zone2["Zone 2: Deterministic Governance Choke Point"]
        GATE["ExecutionController (Mandatory Gate)"]
        OPA["Open Policy Agent (Rego Invariants)"]
        RISK["RiskEngine (Blast Radius Calculation)"]
        SIM["SimulationService (Dry-Run Verification)"]
        APP_SVC["ApprovalService (Human-in-the-Loop)"]
        GATE --> OPA
        GATE --> RISK
        GATE --> SIM
        GATE --> APP_SVC
    end

    subgraph Zone3["Zone 3: Concurrency & State Management"]
        LOCK["PostgreSQL 16 Row-Level Leases\n(SELECT ... FOR UPDATE)"]
        FENCE["Monotonic Fencing Tokens\n(Zombie Worker Defense)"]
        IDEMP["Idempotency SHA-256 Hashing"]
        LOCK --- FENCE --- IDEMP
    end

    subgraph Zone4["Zone 4: Progressive Actuation Engine"]
        CANARY["CanaryEvaluator\nTraffic Splitting: 10% -> 25% -> 50% -> 100%"]
        RECON["Reconciliation Loop\nInterrupted Workflow Self-Healing"]
        ACT["Kubernetes / NGINX Ingress Actuator"]
        CANARY --> ACT
        RECON --> ACT
    end

    subgraph Zone5["Zone 5: Infrastructure & Authoritative Evidence"]
        K8S["Kubernetes Cluster & Ingress"]
        PROM["Prometheus Time-Series Telemetry"]
        PG["PostgreSQL 16 DB (Alembic Head)"]
    end

    PLAN -->|Submit Proposed Plan| GATE
    GATE -->|Acquire Execution Lease| LOCK
    LOCK -->|Granted Lease + Fencing Token| CANARY
    CANARY -->|PromQL Telemetry Query| PROM
    ACT -->|Execute Actuation| K8S
    RECON -->|Authoritative Cluster Readback| K8S
    LOCK -->|Persist Leases & Tasks| PG

    style Zone1 fill:#1e1b4b,stroke:#818cf8,stroke-width:1px,color:#f8fafc
    style Zone2 fill:#450a0a,stroke:#f87171,stroke-width:2px,color:#f8fafc
    style Zone3 fill:#0f172a,stroke:#38bdf8,stroke-width:1px,color:#f8fafc
    style Zone4 fill:#022c22,stroke:#10b981,stroke-width:1px,color:#f8fafc
    style Zone5 fill:#1c1917,stroke:#78716c,stroke-width:1px,color:#f8fafc
```

### Key Technical Decisions (devops-jarvis)

| Decision | Rationale |
|----------|-----------|
| Bounded Autonomy (Mandatory Choke Point) | LLMs cannot be trusted with raw mutation execution due to prompt injection and non-determinism. All actions must be validated by deterministic code. |
| Open Policy Agent (OPA/Rego) | Decouples compliance and safety rules from application code; allows declarative policy updates without recompiling the control plane. |
| PostgreSQL Row-Level Lease Locking | Avoids adding complex distributed consensus systems (e.g., etcd or Consul) when PostgreSQL is already an ACID-compliant requirement. |
| Monotonic Fencing Tokens | Solves the classic distributed split-brain problem when workers pause due to network latency or garbage collection. |
| Epistemic Invariants (`UNKNOWN != SAFE`) | Halts automated canary rollouts immediately if Prometheus metrics are missing, incomplete, or stale. |

---

> All architecture diagrams represent the actual implemented configuration as verified during project execution. No theoretical or aspirational components are included.

