# Project Explanations: Deep-Dive Interview Walkthroughs

Structured conversational narratives designed to answer: *"Walk me through your project from architectural conception to live verification."*

---

## 1. Kubernetes Observability Platform (`kube-obs`)

### The 2-Minute Executive Pitch
> "`kube-obs` is a full-stack Kubernetes observability platform that I built to solve the operational blind spots of running microservices in container clusters. Without holistic telemetry, failures like pod crash-loops, memory saturation, or network drops are invisible until users report downtime.
>
> I packaged the platform with Helm and deployed it on Kubernetes. It collects metrics across three distinct layers: host kernel metrics via Node Exporter running as a DaemonSet, Kubernetes orchestration state via Kube-State-Metrics, and application-level HTTP request rates and latencies from an instrumented Python microservice exposing custom metrics in Prometheus text format.
>
> Downstream, Prometheus evaluates 136 alerting rules against this time-series data. When an anomaly occurs, it dispatches the alert to Alertmanager, which handles grouping, deduplication, and notification routing to webhook receivers. For visualization, Grafana dynamically provisions dashboards from Kubernetes ConfigMaps via sidecar watchers. To ensure production security baselines, all dashboards and APIs are fronted by NGINX Ingress with SNI-based TLS certificate termination.
>
> I validated the entire system through an automated 12-point health check suite and executed controlled pod crash-loop simulations to verify the alert pipeline from Pending to Firing and eventual Resolution."

### Deep-Dive Architectural Walkthrough
1. **Scraping Architecture**: "Prometheus runs as a StatefulSet backed by a Persistent Volume Claim to ensure time-series metrics persist across pod rescheduling. It uses a 15-second scrape loop. For applications, I avoided hardcoded static IP configurations by using Kubernetes pod annotations (`prometheus.io/scrape: 'true'`), allowing Prometheus to dynamically discover new pods as they scale."
2. **Alert Rule Lifecycle**: "Alerts don't just instantly trigger notifications. When a rule condition is met (e.g., `KubePodCrashLooping`), the alert enters a `Pending` state for a configured `for: 2m` duration. This prevents alert fatigue from transient blips. Once the duration passes, it transitions to `Firing`, where Alertmanager batches co-occurring alerts (`group_wait: 10s`) and dispatches a unified webhook payload."
3. **Ingress & Security**: "Rather than using insecure `kubectl port-forward` commands, I configured NGINX Ingress Controller. Hostnames (`grafana.local`, `prometheus.local`, `app.local`) resolve to the cluster IP and terminate TLS using Kubernetes TLS secrets."

---

## 2. GitOps CI/CD Delivery Platform (`git-argo`)

### The 2-Minute Executive Pitch
> "`git-argo` is an end-to-end GitOps continuous delivery platform integrating GitLab CI/CD, GitHub, Argo CD, Helm, and Kubernetes. The core problem it solves is the traditional 'CI pushes to Kubernetes' anti-pattern, where CI runners hold cluster admin credentials and execute imperative kubectl commands.
>
> I architected the platform with strict separation of concerns. Developers push source code to GitLab. A 5-stage `.gitlab-ci.yml` pipeline executes: static validation, Pytest unit tests, an unprivileged multi-stage Docker build using Docker-in-Docker over mTLS, image publishing to GitLab Container Registry with an immutable commit SHA tag, and an automated GitOps promotion step.
>
> In Stage 5, the pipeline uses a masked GitHub Personal Access Token to update the image tag in `helm/gitops-demo/values.yaml` in our GitHub GitOps repository, committing with `[skip ci]`. Inside the Kubernetes cluster, Argo CD continuously watches GitHub. Within minutes of detecting the commit, Argo CD renders the Helm chart and performs a zero-downtime rolling update.
>
> The platform is live-verified: GitLab SaaS Pipeline #3045047835 passed all 5 stages in 3 minutes 7 seconds. I also verified Argo CD's self-healing by manually scaling the cluster out-of-band to 3 replicas—Argo CD immediately detected the drift and terminated the unauthorized pods within seconds."

### Deep-Dive Architectural Walkthrough
1. **Decoupled Repositories**: "Why separate GitLab and GitHub? GitLab owns developer concerns: test reports, build environments, and container registries. GitHub owns the declared production state. By keeping the GitOps manifests in GitHub and letting Argo CD pull into Kubernetes, the cluster requires zero inbound ports, and the CI system holds zero cluster privileges."
2. **Deterministic Immutability**: "We forbid `latest` tags. Every image built is tagged with `${CI_COMMIT_SHORT_SHA}`. This provides an unbroken audit trail: the version running in Kubernetes directly maps to a specific git commit, and rollbacks are accomplished declaratively by running `git revert` on the GitOps repository."
3. **Container Security Hardening**: "The microservice container runs as unprivileged user `appuser` (UID 10001, GID 10001). In the Kubernetes deployment, we strip all Linux capabilities (`drop: [ALL]`), enforce `seccompProfile: RuntimeDefault`, and disable automounting of the Kubernetes API token."

---

## 3. Autonomous AI SRE Control Plane (`devops-jarvis`)

### The 2-Minute Executive Pitch
> "`devops-jarvis` is an autonomous AI DevOps and SRE control plane engineered with Governed Bounded Autonomy. The problem with current AI agent implementations in DevOps is non-determinism: giving an LLM direct shell or Kubernetes admin access creates catastrophic operational risk from prompt injection or hallucinations.
>
> In Jarvis, AI models analyze intent and formulate remediation strategies, but are architecturally barred from touching infrastructure. All mutations must pass through an immutable choke point: the `ExecutionController`. This controller evaluates four deterministic gates: declarative Open Policy Agent (OPA/Rego) rules, dynamic blast-radius risk scoring, two-phase dry-run simulation, and human-in-the-loop approvals for high-risk actions.
>
> For progressive delivery, Jarvis drives multi-stage canary traffic splitting (10% → 25% → 50% → 100%) against NGINX Ingress, evaluating live Prometheus metrics under strict epistemic invariants (`UNKNOWN != SAFE`, `STALE != FRESH`). For distributed concurrency, it uses PostgreSQL 16 row-level locks and monotonic fencing tokens to prevent split-brain collisions.
>
> The platform is currently at Milestone 9 Phase 3 Complete, backed by a deterministic test suite of 1,419 passing tests with zero failures."

### Deep-Dive Architectural Walkthrough
1. **Bounded Autonomy Choke Point**: "The core invariant is that LLMs propose, but deterministic code approves and actuates. The OPA engine runs declarative Rego policies enforcing hard guardrails: no production changes during freeze windows, no root containers, and no mutations to control plane namespaces."
2. **Epistemic Invariants in Canary Rollouts**: "Most automated canary tools check if error rates are below a threshold. But what if the Prometheus scraper crashed? The query returns 0 errors simply because data is missing. Jarvis enforces `UNKNOWN != SAFE`: if metrics are missing or sample sizes are inadequate, promotion immediately halts."
3. **Distributed Concurrency & Self-Healing**: "To prevent race conditions, workers acquire PostgreSQL row-level leases with `SELECT ... FOR UPDATE` and receive a monotonic fencing token. If a worker pauses and its lease expires, a newer worker takes over. When the paused worker wakes up, the database rejects its transaction because its token is obsolete. Furthermore, on startup or periodic ticks, reconciliation loops perform authoritative cluster readbacks to resume interrupted workflows autonomously."

