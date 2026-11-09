# Project Overview: Kubernetes Observability Platform (`kube-obs`)

**Repository**: [github.com/SUPRAVAT001/kube-obs](https://github.com/SUPRAVAT001/kube-obs)  
**Status**: Production-Ready Baseline (12/12 Automated Checks Passed)  
**Primary Domain**: Cloud-Native Observability, Monitoring, Alerting & SRE

---

## 1. Problem Statement

Operating containerized workloads in Kubernetes without holistic telemetry creates critical operational blind spots:
* **Silent Failures**: Pods crashing in crash-loop backoff or silently saturating cgroup memory limits are invisible until external users report downtime.
* **Lack of Historical Context**: Container ephemeral lifecycles mean logs and state vanish when a pod is rescheduled, making post-incident root cause analysis difficult.
* **Unstructured Ingress**: Exposing monitoring dashboards via insecure HTTP or ad-hoc port-forwarding violates production security baselines and impedes team access.

The **Kubernetes Observability Platform** was built to solve these challenges by deploying a self-contained, automated, full-stack telemetry and incident routing platform on Kubernetes.

---

## 2. Key Objectives & Outcomes

1. **Full-Stack Ingestion**: Collect real-time time-series metrics from the Linux host kernel, Kubernetes orchestration API objects, container cgroups, and application HTTP endpoints.
2. **Automated Incident Alerting**: Implement 136 production-grade alerting rules in Prometheus, routing notifications through Alertmanager to external webhook endpoints with multi-stage lifecycle evaluation (Inactive → Pending → Firing → Resolved).
3. **Declarative Visualization as Code**: Auto-provision Grafana data sources and production dashboards from Kubernetes ConfigMaps using dynamic sidecar providers, eliminating manual UI configuration.
4. **Encrypted Ingress**: Provide secure, TLS-terminated access to `grafana.local`, `prometheus.local`, and `app.local` via NGINX Ingress Controller.
5. **Deterministic Verification**: Deliver an automated 12-point end-to-end test script verifying component health, metric scraping, secret hygiene, and failure recovery.

---

## 3. Technology Stack & Component Inventory

| Layer | Component | Version | Responsibility |
| :--- | :--- | :--- | :--- |
| **Orchestrator** | Kubernetes | v1.35.1 | Container clustering and workload scheduling (Minikube runtime) |
| **Packaging** | Helm | v3.22.0 | Declarative stack deployment (`kube-prometheus-stack` chart) |
| **Time-Series DB** | Prometheus Server | v3.15.1 | Scrape engine, TSDB time-series storage, alert evaluation |
| **Visualization** | Grafana | v13.3.0 | SRE dashboards, panel queries, sidecar datasource provisioning |
| **Alert Routing** | Alertmanager | v0.28.0 | Alert grouping, deduplication, inhibition, webhook notification |
| **Host Metrics** | Node Exporter | v1.9.0 | Host CPU mode, memory, disk I/O, network traffic (DaemonSet) |
| **Cluster Metrics** | Kube-State-Metrics | v2.15.0 | Deployments, replica counts, pod phases, container exit codes |
| **Ingress Controller**| NGINX Ingress | v1.14.0 | HTTPS reverse proxy with SNI-based TLS secret termination |
| **Demo Microservice**| `observability-demo`| v1.0.1 | Python/FastAPI app exposing custom Prometheus `/metrics` |
| **Container Engine** | Docker | v29.2.1 | Multi-stage unprivileged container builds |

---

## 4. Key Architectural Capabilities

* **Declarative Target Discovery**: Utilizes Kubernetes pod annotations (`prometheus.io/scrape: "true"`, `prometheus.io/path: "/metrics"`, `prometheus.io/port: "8080"`) to automatically discover and scrape application endpoints without modifying Prometheus configuration files.
* **Persistent Telemetry**: Persistent Volume Claims (PVCs) protect historical Prometheus TSDB metrics and Grafana user settings across node reboots or pod rescheduling.
* **Safe Teardown Automation**: Scripted lifecycle tools (`scripts/uninstall.sh`) preserve persistent volume claims by default to safeguard historical time-series data during platform maintenance.

