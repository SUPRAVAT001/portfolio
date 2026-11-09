# Professional Summary

**Supravat Dash**  
DevOps Engineer · Platform Engineer · Site Reliability Engineer  
GitHub: [github.com/SUPRAVAT001](https://github.com/SUPRAVAT001) · GitLab: [gitlab.com/supravatdash7399](https://gitlab.com/supravatdash7399)

---

## Executive Summary

DevOps and Systems Engineer with comprehensive hands-on expertise in **Kubernetes platform engineering**, **GitOps continuous delivery**, **cloud-native observability**, and **autonomous infrastructure automation**. Proven track record of independently designing, building, hardening, and verifying end-to-end delivery pipelines and monitoring platforms from scratch on Linux and Kubernetes environments.

Specialized in bridging application code and resilient runtime infrastructure:
* Authored 5-stage GitLab CI/CD pipelines deploying unprivileged container workloads to Kubernetes via Argo CD with continuous reconciliation, drift detection, and automated self-healing.
* Engineered complete Kubernetes telemetry stacks integrating Prometheus, Grafana, Alertmanager, and NGINX Ingress with TLS, validating alert pipelines through controlled pod failures and automated 12-point health suites.
* Developed autonomous AI-driven SRE control planes (DevOps Jarvis) incorporating deterministic OPA policy gates, risk assessment engines, pre-execution simulation, and distributed PostgreSQL lease locking backed by 1,419 passing automated test cases.

Deep practical understanding of Linux kernel primitives (namespaces, cgroups, memory accounting), container security hardening (non-root UID 10001, capability stripping, seccomp), Helm packaging, and Python/FastAPI backend microservice development.

---

## Core Technical Profile

```
┌─────────────────────────┬────────────────────────────────────────────────────────────────────────┐
│ DOMAIN                  │ KEY TECHNOLOGIES & PRACTICAL PROFICIENCIES                             │
├─────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ Container Orchestration │ Kubernetes (Minikube runtime), Helm v3, Docker, containerd, cgroups,   │
│                         │ Namespaces, Deployments, StatefulSets, DaemonSets, Services, Ingress   │
├─────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ CI/CD & GitOps          │ GitLab CI/CD (5-stage DAG pipelines), Argo CD, GitHub, Docker-in-Docker│
│                         │ (DinD), GitLab Container Registry, Declarative Rollbacks, Drift Healing│
├─────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ Observability & SRE     │ Prometheus (TSDB, PromQL, Alert Rules), Alertmanager, Grafana, Node    │
│                         │ Exporter, Kube-State-Metrics, NGINX Ingress (TLS), Webhook Routing     │
├─────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ Languages & Frameworks  │ Python 3.12, FastAPI, Bash / POSIX Shell, SQL, Pytest, YAML, Jinja2    │
├─────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ Database & Governance   │ PostgreSQL 16 (Row-level locking, ACID), Alembic, Open Policy Agent    │
│                         │ (OPA/Rego), Risk Engines, Distributed Lease Locks, Monotonic Fencing   │
├─────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ Security & Hardening    │ Non-root execution (UID 10001), Linux capability drop (ALL), Seccomp   │
│                         │ RuntimeDefault, Masked CI Secrets, automountServiceAccountToken: false │
└─────────────────────────┴────────────────────────────────────────────────────────────────────────┘
```

---

## Key Achievements & Verifiable Evidence

1. **Hosted GitLab CI/CD SaaS Pipeline Execution**: Executed full 5-stage cloud pipeline ([#3045047835](https://gitlab.com/supravatdash7399/git-argo/-/pipelines/3045047835)) validating code, running Pytests, building multi-stage unprivileged Docker containers, publishing to GitLab Registry, and autonomously promoting GitHub GitOps tags via a masked PAT.
2. **Automated Drift Detection & Self-Healing**: Verified live in Kubernetes — manual replica scaling to 3 was detected within seconds by Argo CD as `OutOfSync` and automatically remediated back to the declared 1 replica with zero human intervention.
3. **Declarative Zero-Downtime Rollback**: Demonstrated rolling update rollbacks executed entirely via Git (`git revert`) without running imperative `kubectl rollout` commands.
4. **Full-Stack Telemetry & Alert Testing**: Built and validated a 136-rule Prometheus and Alertmanager stack on Kubernetes, verifying transition from Pending to Firing and webhook notification dispatch under simulated pod failure.
5. **High-Assurance SRE Control Plane**: Engineered core milestones of DevOps Jarvis, delivering 1,419 verified tests across canary progression, distributed lease concurrency, and interrupted workflow self-healing loops.

