# Resume Project Descriptions

ATS-optimized, technically accurate project descriptions for all three engineering platforms.
Use the format appropriate for the target resume section and word-count context.

---

## Project 1: Kubernetes Observability Platform (`kube-obs`)

### Two-Line Version (ATS — Resume Header / LinkedIn)
> Designed and deployed a full-stack Kubernetes observability platform integrating Prometheus, Alertmanager, and Grafana with custom alert rules and TLS-terminated NGINX ingress. Implemented controlled failure scenarios demonstrating end-to-end alert pipeline activation from pod crash-loop detection through webhook notification dispatch.

### Four-Bullet Version (Resume Projects Section)
* Architected and deployed a Kubernetes observability stack on Minikube using Helm, integrating **Prometheus** for metrics collection, **Alertmanager** for alert routing, and **Grafana** for dashboard visualization across infrastructure and application telemetry.
* Configured **kube-state-metrics** and **Node Exporter** as Prometheus scrape targets, supplemented by a FastAPI microservice exposing a custom `/metrics` endpoint in Prometheus text format with pod annotation-based auto-discovery.
* Authored Alertmanager alerting rules for crash-loop detection, pod unavailability, and memory thresholds; validated the full alert pipeline via controlled pod termination triggering Prometheus firing state through to webhook receiver notification.
* Deployed **NGINX Ingress Controller** with TLS termination, providing HTTPS-secured external access to Grafana dashboards and application endpoints within the Kubernetes cluster.

### Detailed Interview Explanation (~200 words)
> "I built `kube-obs` to solve a real operational problem: running Kubernetes without observability means you're flying blind. If a pod crashes or memory spikes, you need to know immediately — not when a user complains.
>
> The architecture follows the standard cloud-native observability pattern. Prometheus scrapes metrics every 15 seconds from Node Exporter (host-level CPU, memory, disk), kube-state-metrics (Kubernetes object state — deployments, replica counts, pod phases), and a FastAPI demo application I wrote that exposes custom metrics in Prometheus text format. I used pod annotations (`prometheus.io/scrape: 'true'`) so Prometheus discovers application targets automatically without touching its config file for every new service.
>
> Alertmanager sits downstream from Prometheus and receives fired alerts. I wrote rules covering crash-loop backoff and pod unavailability, then validated them by deliberately terminating pods and watching the alert transition from `pending` to `firing` state.
>
> Grafana connects to Prometheus via PromQL and renders dashboards for node resource utilization and application telemetry. TLS termination happens at the NGINX Ingress Controller so external access uses HTTPS, which matters in any real environment.
>
> The whole stack is Helm-packaged, so it deploys reproducibly with `helm install` and a `values.yaml`."

---

## Project 2: GitOps CI/CD Delivery Platform (`git-argo`)

### Two-Line Version (ATS — Resume Header / LinkedIn)
> Implemented a production-pattern GitOps continuous delivery platform connecting a 5-stage GitLab CI/CD pipeline through container image publishing to automated Kubernetes deployment via Argo CD. Demonstrated drift detection, self-healing, and declarative rollback; executed end-to-end on hosted GitLab SaaS (Pipeline #3045047835, all stages passed, image deployed and verified live).

### Four-Bullet Version (Resume Projects Section)
* Designed and implemented an end-to-end GitOps delivery pipeline integrating **GitLab CI/CD** (validation, Pytest testing, Docker image build/publish) with **GitHub** as the deployment source of truth and **Argo CD** for automated Kubernetes reconciliation.
* Authored a 5-stage `.gitlab-ci.yml` pipeline that builds immutable container images tagged with `${CI_COMMIT_SHORT_SHA}`, publishes to **GitLab Container Registry**, and autonomously updates Helm `values.yaml` in the GitHub GitOps repository via a masked `GITOPS_GITHUB_TOKEN`, triggering Argo CD synchronization without manual intervention.
* Configured Argo CD with `selfHeal: true` and demonstrated **drift detection** (manual `kubectl scale` immediately detected as OutOfSync) and **declarative rollback** (version downgrade executed entirely via `git revert`, zero `kubectl` commands).
* Implemented container security hardening: multi-stage Docker builds, non-root user (UID 10001), Linux capability stripping (`drop: [ALL]`), `seccompProfile: RuntimeDefault`, and strict Kubernetes resource limits (`200m` CPU, `128Mi` memory).

### Detailed Interview Explanation (~200 words)
> "I built `git-argo` to implement the GitOps pattern properly — where Git is the single source of truth for cluster state, not kubectl commands. The core problem with imperative deployments is that there's no audit trail, rollback is a separate command, and drift between what's in Git and what's in the cluster can silently accumulate.
>
> The architecture splits concerns deliberately: GitLab handles everything CI-related — syntax checking, running Pytest, building the Docker image with Docker-in-Docker, and publishing to its own registry. GitHub holds the deployment configuration — specifically `helm/gitops-demo/values.yaml` which declares what image the cluster should run. These two concerns are separated because they have different access patterns, different audiences, and different security requirements.
>
> Stage 5 of my pipeline is where the two worlds connect: it clones the GitHub repo, runs `sed` to update the image tag to the commit SHA, commits with `[skip ci]` to avoid infinite loops, and pushes. Argo CD sees that commit within 3 minutes and applies the Helm chart to Kubernetes.
>
> I ran into three real pipeline failures — a YAML colon parser issue, an alpine/git entrypoint conflict, and an incorrect image repository reference — and debugged each from first principles. That troubleshooting is documented in my GitLab commit history."

---

## Project 3: Autonomous AI SRE Control Plane (`devops-jarvis`)

### Two-Line Version (ATS — Resume Header / LinkedIn)
> Engineered a governed autonomous SRE control plane in Python/FastAPI using Open Policy Agent (OPA) and PostgreSQL distributed locking to enforce deterministic execution safety gates, metric-driven canary progression, and interrupted workflow recovery across Kubernetes workloads (1,419 automated tests passing).

### Four-Bullet Version (Resume Projects Section)
* Architected a **Governed Bounded Autonomy** AI control plane for cloud-native infrastructure, implementing a mandatory `ExecutionController` choke point that evaluates declarative OPA/Rego policies, dynamic risk scores, and pre-execution dry-run simulations before mutating Kubernetes clusters.
* Implemented autonomous progressive delivery loops driving multi-stage canary traffic splitting (10% → 25% → 50% → 100%) against NGINX Ingress, evaluating live Prometheus time-series metrics under strict epistemic safety invariants (`UNKNOWN != SAFE`, `STALE != FRESH`).
* Engineered distributed concurrency control using **PostgreSQL 16 row-level locks** (`SELECT ... FOR UPDATE`), monotonic fencing tokens to prevent zombie worker split-brain mutations, and SHA-256 idempotency hashing.
* Designed self-healing reconciliation loops for startup and periodic ticks that perform authoritative cluster readbacks to detect and resume interrupted workflows without human intervention, verified across **1,419 automated test cases** (0 failures).

### Detailed Interview Explanation (~200 words)
> "DevOps Jarvis is an autonomous SRE control plane that operates on the principle of Governed Bounded Autonomy. The core problem with AI in infrastructure is non-determinism: giving an LLM direct shell or kubectl access is a recipe for catastrophic outages.
>
> In Jarvis, AI models extract intent and formulate plans, but they are architecturally barred from touching infrastructure directly. Every mutation must pass through a strict choke point: the `ExecutionController`. This controller runs four deterministic gates: an Open Policy Agent (OPA) gate with Rego policies, a dynamic risk scoring engine evaluating blast radius, a two-phase simulation service that verifies cluster preconditions, and an approval service for high-risk actions.
>
> For execution, I implemented distributed lease locking with PostgreSQL row-level locks and monotonic fencing tokens to ensure that if a worker node pauses or partitions, stale workers cannot commit conflicting cluster state.
>
> For rollouts, the autonomous canary engine reads live Prometheus metrics and advances traffic through stages, but enforces safety invariants: if telemetry is missing, it halts promotion. It's backed by 1,419 passing automated tests."

---

## Combined One-Liner for Profile / Bio

> DevOps & SRE Engineer with verified expertise across full-stack Kubernetes observability (Prometheus/Grafana/Alertmanager), declarative GitOps CI/CD delivery (GitLab CI → Argo CD), and governed autonomous infrastructure control planes with deterministic safety gates.

---

## Keyword Reference (ATS Optimization)

`Kubernetes` · `Helm` · `Docker` · `GitLab CI/CD` · `GitHub Actions` · `Argo CD` · `GitOps` · `Prometheus` · `Grafana` · `Alertmanager` · `FastAPI` · `Python 3.12` · `Pytest` · `NGINX Ingress` · `TLS / SSL` · `Open Policy Agent (OPA)` · `Rego` · `PostgreSQL 16` · `Distributed Locking` · `Fencing Tokens` · `Canary Rollouts` · `Progressive Delivery` · `Container Security` · `Non-root Containers` · `Multi-stage Docker Builds` · `Infrastructure as Code` · `Drift Detection` · `Self-Healing` · `Microservices` · `REST APIs` · `Observability` · `SRE` · `Linux`
