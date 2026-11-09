# Technical Highlights: Kubernetes Observability Platform (`kube-obs`)

Key technical implementations, validation results, and operational runbooks.

---

## 1. 136 Production Alerting Rules

The platform ships with **136 alerting rules** defined declaratively across infrastructure, container runtime, Kubernetes core, and application telemetry:

| Rule Category | Example Alerts | Target Conditions | Severity |
| :--- | :--- | :--- | :--- |
| **Node Health** | `NodeMemoryHighUtilization`<br>`NodeDiskSpaceFillingUp`<br>`NodeHighCPULoad` | Free memory < 10%<br>Disk space < 15% predicted exhaustion in 6h<br>Node load5 / CPU cores > 1.5 | Critical<br>Warning<br>Warning |
| **Cluster State** | `KubePodCrashLooping`<br>`KubeDeploymentReplicasMismatch`<br>`KubePodNotReady` | Rate of container restarts > 0 for 5m<br>Available replicas != Desired replicas for 15m<br>Pod in non-ready phase > 15m | Critical<br>Warning<br>Warning |
| **Application SRE** | `AppHighErrorRate`<br>`AppEndpointDown`<br>`AppLatencyHigh` | 5xx HTTP response rate > 5% over 5m<br>`up{job="observability-demo"} == 0` for 1m<br>p95 HTTP latency > 500ms for 5m | Critical<br>Critical<br>Warning |

---

## 2. Controlled Failure & Recovery Verification

To prove the operational validity of the alerting pipeline, controlled failure experiments were conducted and captured:

### Failure Scenario: Deliberate Pod Crash-Loop Simulation
1. An intentional application failure was introduced by passing invalid configurations to the demo microservice.
2. The pod entered `CrashLoopBackOff`, triggering immediate state changes in `kube-state-metrics`.
3. **Prometheus Detection**:
   * Evaluated rule: `KubePodCrashLooping`
   * Alert state transitioned from `Inactive` → `Pending` (observed for 2 minutes).
   * After the duration elapsed, the alert transitioned to `Firing`.
4. **Alertmanager Routing**:
   * Alert was batched and dispatched to the local webhook notification receiver.
   * Webhook confirmed receipt of HTTP POST containing alert severity, pod name, and runbook URL.
5. **Recovery**:
   * Workload configuration was corrected; pod resumed healthy state (`1/1 Running`).
   * Prometheus evaluated the condition as resolved and Alertmanager dispatched a green `Resolved` payload.

---

## 3. Automated 12-Point Test Suite

The platform includes an automated end-to-end verification harness (`scripts/validate.sh`) that executes 12 deterministic checks:

```
[PASS]  1. Kubernetes node is in Ready state
[PASS]  2. Observability namespace exists and is active
[PASS]  3. Prometheus server StatefulSet is healthy (1/1 Ready)
[PASS]  4. Alertmanager StatefulSet is healthy (1/1 Ready)
[PASS]  5. Grafana deployment is healthy (1/1 Ready)
[PASS]  6. Node Exporter DaemonSet is scheduled and ready across nodes
[PASS]  7. Kube-State-Metrics deployment is healthy (1/1 Ready)
[PASS]  8. Demo microservice deployment is healthy (2/2 Ready)
[PASS]  9. Prometheus targets active and scraping without scrape errors
[PASS] 10. Grafana datasources auto-provisioned and responding to PromQL
[PASS] 11. NGINX Ingress Controller routing HTTPS traffic with TLS certificates
[PASS] 12. Alertmanager routing rules and webhook receivers reachable
```

---

## 4. Visual Evidence & Screenshots

Authentic screenshots from live cluster verification are archived in [`evidence/kube-obs/`](../../evidence/kube-obs):

* [`cluster-overview.png`](../../evidence/kube-obs/cluster-overview.png): Cluster-wide CPU, memory, and pod scheduling density dashboard.
* [`node-monitoring.png`](../../evidence/kube-obs/node-monitoring.png): Deep host telemetry from Node Exporter (kernel, load averages, I/O).
* [`application-monitoring.png`](../../evidence/kube-obs/application-monitoring.png): FastAPI application telemetry dashboard tracking request rates, errors, and latencies.
* [`prometheus-targets.png`](../../evidence/kube-obs/prometheus-targets.png): Prometheus service discovery table showing all targets in `UP` state.
* [`alert-firing.png`](../../evidence/kube-obs/alert-firing.png): Alertmanager UI showing active `Firing` alerts during controlled crash simulation.
* [`alert-recovery.png`](../../evidence/kube-obs/alert-recovery.png): Alert transition to `Resolved` after container recovery.
* [`validation.png`](../../evidence/kube-obs/validation.png): Terminal execution output of the 12-point automated validation script.

