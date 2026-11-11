# Architecture: Kubernetes Observability Platform (`kube-obs`)

[Project Overview](README.md) · [Source Repository](https://github.com/SUPRAVAT001/kube-obs)

---

## System Architecture

```mermaid
flowchart TD
    CLIENT["Local Client (/etc/hosts -> Cluster Ingress IP)"] -->|HTTPS :443| NGINX

    subgraph K8s["Minikube Cluster (Kubernetes v1.35.1)"]
        NGINX["NGINX Ingress Controller v1.14.0\nTLS Termination (observability-tls-secret)"]

        subgraph Obs["Namespace: observability"]
            GF["Grafana v13.3.0\nConfigMap k8s-sidecar\n3 Provisioned Dashboards"]
            PROM["Prometheus Server v3.15.1\nPrometheus Operator + TSDB (2Gi PVC)\n10s Scrape & Rule Evaluation"]
            AM["Alertmanager v0.28.0\nGrouping & local-webhook Routing"]
            NE["Node Exporter v1.9.0\nDaemonSet (Host /proc & /sys)"]
            KSM["kube-state-metrics v2.15.0\nKubernetes API Object State"]
            APP["observability-demo v1.0.1\n2 Replicas (Python http.server + prometheus_client)\n/metrics, /api/degrade, /api/webhook/alerts"]
        end
    end

    NGINX -->|grafana.local| GF
    NGINX -->|prometheus.local| PROM
    NGINX -->|app.local| APP

    GF -->|PromQL Queries| PROM
    PROM -->|10s Scrape via ServiceMonitor| APP
    PROM -->|10s Scrape| NE
    PROM -->|10s Scrape| KSM
    PROM -->|136 Rules Evaluated -> Firing Alerts| AM
    AM -->|POST /api/webhook/alerts| APP
```

---

## Component Stack

| Layer | Component | Version | Role |
| :--- | :--- | :--- | :--- |
| **Orchestration** | Kubernetes (Minikube) | v1.35.1 | Single-node cluster orchestration |
| **Packaging** | Helm (`kube-prometheus-stack`) | v3.22.0 | Declarative Prometheus Operator & stack deployment |
| **Metrics & TSDB** | Prometheus Server | v3.15.1 | Time-series scraping, 2Gi PVC TSDB, 136 alert rules |
| **Visualization** | Grafana | v13.3.0 | PromQL dashboards auto-synced via `k8s-sidecar` |
| **Alert Routing** | Alertmanager | v0.28.0 | Alert grouping, deduplication, and webhook dispatch |
| **Exporters** | Node Exporter / Kube-State-Metrics | v1.9.0 / v2.15.0 | Host kernel telemetry & cluster object state |
| **Ingress** | NGINX Ingress Controller | v1.14.0 | HTTPS reverse proxy with SAN TLS certificates |
| **Workload** | `observability-demo` | v1.0.1 | Unprivileged Python HTTP service (`UID 10001`, 2 replicas) |

---

## Alert Lifecycle Flow

```mermaid
sequenceDiagram
    participant Test as Operator / curl
    participant App as observability-demo
    participant Prom as Prometheus (10s interval)
    participant AM as Alertmanager

    Test->>App: POST /api/degrade
    Note over App: Sets app_health_status = 0
    Prom->>App: GET /metrics (ServiceMonitor)
    Prom->>Prom: Evaluate ObservabilityDemoHealthDegraded (for: 15s)
    Prom->>AM: Dispatch FIRING alert
    AM->>App: POST /api/webhook/alerts (status: firing)
    Test->>App: POST /api/recover
    Note over App: Restores app_health_status = 1
    Prom->>AM: Dispatch RESOLVED notification
    AM->>App: POST /api/webhook/alerts (status: resolved)
```

---

## Security Controls

* **Workload Isolation**: Runs `observability-demo` under Kubernetes Restricted Pod Security Standards (`runAsNonRoot: true`, `UID 10001`, `allowPrivilegeEscalation: false`, `drop: [ALL]`, `seccompProfile: RuntimeDefault`).
* **Encrypted Edge**: HTTPS enforced via NGINX Ingress and local SAN TLS Secrets (`grafana.local`, `prometheus.local`, `app.local`).
* **Secret Hygiene**: Grafana admin credentials are generated inside Kubernetes Secrets without plaintext defaults checked into Git.
