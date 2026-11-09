# Interview Preparation Guide

Detailed Q&A for DevOps Engineer, Platform Engineer, SRE, and Cloud Engineer interviews.
Answers are grounded in actual project implementations — not generic textbook material.

---

## Linux & Systems

**Q1. How do you check memory usage on a Linux system? What would you look at to understand why a process is consuming excess memory?**

> Start with `free -h` for overall picture — total, used, free, and available (available is the number that matters for new allocations). For process-level analysis, `top` or `htop` sorted by `%MEM`. For deeper investigation: `/proc/<pid>/status` (VmRSS for resident set, VmSwap for swapped memory), `pmap -x <pid>` for memory segment breakdown, or `smem` if installed for proportional set size.
>
> In the context of my Minikube work: I had ~700 MiB available on a 4.3 GiB WSL2 node with Argo CD, kube-obs, and gitops-demo all running. I used `free -h` and checked `kubectl top nodes` to understand headroom before each deployment.

---

**Q2. What is the difference between a process and a container from a Linux kernel perspective?**

> Both are Linux processes — a container is not a fundamentally different primitive. The isolation comes from Linux kernel namespaces (PID, net, mnt, uts, ipc, user) and cgroups. Namespaces give the container its own view of the system: its own PID 1, its own network interfaces, its own filesystem root. Cgroups enforce resource limits — CPU, memory, block I/O. The container runtime (containerd, runc) calls `clone()` with the appropriate namespace flags and sets up the cgroup hierarchy.
>
> This is why container escapes are possible — the kernel is shared. It's also why `seccompProfile: RuntimeDefault` and `capabilities.drop: [ALL]` matter: they reduce the kernel attack surface exposed to processes inside the container.

---

**Q3. What does `runAsNonRoot: true` enforce and why is it important?**

> It's a Kubernetes admission-level check that rejects containers whose image has `USER root` (UID 0) or no USER directive. It's not enforced by the container runtime independently — it's checked by the kubelet when creating the pod. Combined with `runAsUser: 10001`, it means the process inside the container runs with a non-privileged UID.
>
> In my `git-argo` Helm chart I set both `runAsNonRoot: true` and `runAsUser: 10001` in `podSecurityContext`, and the Docker image is built with `USER 10001` in the Dockerfile. This ensures consistency: the image enforces it at build time, Kubernetes enforces it at admission time.

---

**Q4. Explain Linux file descriptors and why they matter in containerized applications.**

> File descriptors are integer handles the kernel assigns to open files, sockets, pipes, and devices. Standard streams (stdin=0, stdout=1, stderr=2) are file descriptors. Containers inherit the same fd model. Leaking file descriptors — opening files in loops without closing them — can exhaust the per-process limit (`ulimit -n`), causing "too many open files" errors. In Kubernetes, application logs go to stdout/stderr (fd 1/2) and are captured by the container runtime. This is why well-behaved containerized apps log to stdout, not to log files — it integrates with `kubectl logs` and log aggregators without side-channel configuration.

---

**Q5. What is a cgroup and how does Kubernetes use it to enforce resource limits?**

> A cgroup (control group) is a Linux kernel mechanism for grouping processes and applying resource accounting and limits. Kubernetes creates a cgroup hierarchy per pod and per container. When you set `resources.limits.memory: 128Mi` in Kubernetes, the kubelet writes that value to the container's cgroup memory limit file (e.g., `memory.max` for cgroups v2). If the process exceeds that limit, the kernel OOM killer terminates it. CPU limits translate to CFS quota settings in the cgroup. Requests are used by the scheduler for placement decisions but don't create hard kernel limits.

---

## Docker

**Q6. What is a multi-stage Docker build and why did you use one?**

> A multi-stage build uses multiple `FROM` instructions in a single Dockerfile. Each stage creates an intermediate layer that can be selectively copied from. The final image only contains what you explicitly `COPY --from=<stage>`. The benefit: build tools, compilers, test dependencies, and intermediate files never land in the production image.
>
> In `git-argo`, the Dockerfile has a `builder` stage that installs Python dependencies (which pulls build tools like gcc for any C extensions), and a `runtime` stage that only copies the installed packages and application code. The final image is smaller and has a smaller attack surface — no pip, no build tools, no package cache.

---

**Q7. How does Docker-in-Docker (DinD) work in GitLab CI and what are its security implications?**

> Docker-in-Docker runs a Docker daemon as a GitLab CI service container (`docker:27-dind`). The job container (`docker:27-cli`) connects to this daemon over TLS (port 2376) via the `DOCKER_HOST` environment variable. This allows CI jobs to run `docker build` and `docker push` without access to the host's Docker socket.
>
> In my `.gitlab-ci.yml`:
> ```yaml
> services:
>   - docker:27-dind
> variables:
>   DOCKER_HOST: tcp://docker:2376
>   DOCKER_TLS_CERTDIR: "/certs"
>   DOCKER_TLS_VERIFY: 1
> ```
> The TLS certificates are shared between the DinD service and the job via a mounted volume (`/certs`). The security implication: the DinD daemon runs privileged. This is acceptable in GitLab SaaS shared runners (they're ephemeral, disposable) but would require careful consideration in self-hosted environments. An alternative is rootless Docker or Kaniko (builds without a daemon).

---

**Q8. What is the difference between COPY and ADD in a Dockerfile?**

> `COPY` copies files from the build context into the image — that's it. `ADD` does the same but also supports URL fetching and automatic extraction of tar archives. Best practice: always use `COPY` unless you specifically need the tar extraction behavior. `ADD` with URLs is an anti-pattern because it can't leverage the Docker layer cache effectively and obscures what's being added. My Dockerfile uses `COPY` exclusively.

---

**Q9. How does `.dockerignore` affect build performance and security?**

> `.dockerignore` excludes files from the build context sent to the Docker daemon. The build context is an entire directory tree transferred over a socket before the build starts. Without `.dockerignore`, a directory with `.git/`, `node_modules/`, or test artifacts sends megabytes of irrelevant data. More critically: without `.dockerignore`, secrets stored in local `.env` files, kubeconfigs, or SSH keys could accidentally be `COPY`-ed into the image. My `.dockerignore` excludes `.git`, `__pycache__`, `*.pyc`, `.env`, virtual environments, and test reports.

---

**Q10. What does `EXPOSE` in a Dockerfile actually do?**

> `EXPOSE` is documentation — it records which port the container is intended to listen on. It does not publish the port or create any firewall rule. The actual port binding happens at `docker run -p <host>:<container>` or via Kubernetes Service configuration. I expose port 8080 in my Dockerfile (the FastAPI Uvicorn port) and map it to port 80 via the Kubernetes Service (`port: 80, targetPort: 8080`).

---

## Kubernetes

**Q11. What is the difference between a Deployment and a StatefulSet?**

> A Deployment manages stateless pods — each pod is interchangeable, can be scheduled on any node, and receives a random name suffix. When you scale down, any pod may be terminated. A StatefulSet manages stateful pods with stable network identities (persistent pod names like `prometheus-0`, `prometheus-1`), ordered startup/shutdown, and stable persistent volume claims that follow the pod if it's rescheduled.
>
> In `kube-obs`: Prometheus and Alertmanager use StatefulSets because they have persistent volumes (TSDB data, alert state) and need stable storage identity. Grafana can be a Deployment if dashboard state is externalised. In `git-argo`: the FastAPI app is a Deployment — it's stateless, any pod is equivalent.

---

**Q12. Explain liveness and readiness probes. How do they differ and when does each matter?**

> **Liveness probe**: "Is this container still alive?" Kubernetes restarts the container if the probe fails. Used to recover from deadlocks or corrupted internal state where the process is running but non-functional.
>
> **Readiness probe**: "Is this container ready to receive traffic?" Kubernetes removes the pod from Service endpoints (stops routing requests to it) if the probe fails. The pod is not restarted. Used to prevent traffic from reaching a pod that hasn't finished startup or is temporarily overloaded.
>
> In my `git-argo` Helm chart:
> ```yaml
> livenessProbe:
>   httpGet: { path: /health, port: http }
>   initialDelaySeconds: 5
>   periodSeconds: 10
>   failureThreshold: 3
> readinessProbe:
>   httpGet: { path: /health, port: http }
>   initialDelaySeconds: 3
>   periodSeconds: 5
>   failureThreshold: 2
> ```
> Both probe `/health`. Readiness fires earlier (3s vs 5s delay) and is more sensitive (fails after 2 misses vs 3). This ensures traffic only reaches the pod once it's genuinely responsive, while giving the liveness probe more patience before triggering a potentially disruptive restart.

---

**Q13. What is a Kubernetes namespace and why did you use separate namespaces in this project?**

> A namespace is a virtual partition within a cluster that scopes names, resource quotas, RBAC policies, and network policies. It's not a security boundary (by default pods in different namespaces can communicate), but it provides organizational isolation, resource quota enforcement per team/application, and clean `kubectl get all -n <namespace>` visibility.
>
> I used three namespaces: `argocd` (Argo CD controllers), `gitops-demo` (my FastAPI application), and `observability` (Prometheus, Grafana, Alertmanager). This meant: Argo CD changes didn't appear in `kubectl get pods -n gitops-demo`, accidental `kubectl delete all` in one namespace couldn't reach another, and resource quotas could be applied independently.

---

**Q14. What is a Kubernetes Service Account and why did you disable automountServiceAccountToken?**

> A Service Account is a Kubernetes identity for pods — it determines what Kubernetes API operations the pod can perform. By default, Kubernetes mounts a JWT token for the pod's service account into every pod at `/var/run/secrets/kubernetes.io/serviceaccount/token`. This token can be used to authenticate to the Kubernetes API server.
>
> For the `gitops-demo` FastAPI application, the app has no reason to call the Kubernetes API. Mounting the token is unnecessary and creates a risk — if the container is compromised, the token could be used for lateral movement within the cluster. I set `automount: false` in `serviceaccount.yaml`, explicitly disabling the mount.

---

**Q15. How does Kubernetes roll out a Deployment update? What is a rolling update strategy?**

> With the default `RollingUpdate` strategy, Kubernetes gradually replaces old pods with new ones. `maxSurge` controls how many extra pods can exist above the desired count during rollout (default 25%). `maxUnavailable` controls how many pods can be absent (default 25%). For a 1-replica deployment, this means: Kubernetes creates 1 new pod (now 2 running temporarily), waits for it to pass readiness, then terminates the old pod. Zero downtime is achieved because the Service only routes to ready pods, and traffic flows to the old pod until the new one is ready.
>
> I verified this in Scenario 2 (version promotion v1→v2) and Scenario 4 (rollback v2→v1) — the Service never had a gap in ready endpoints.

---

## Helm

**Q16. What is Helm and what problem does it solve compared to raw Kubernetes YAML?**

> Helm is a Kubernetes package manager. It templates Kubernetes manifests with Go templating (`{{ .Values.image.tag }}`), packages them into versioned charts, and manages releases (install, upgrade, rollback) with a consistent interface. Without Helm, deploying a multi-component application requires maintaining multiple YAML files, managing env-specific differences by hand, and writing `kubectl apply` scripts. Helm gives you: parameterization via `values.yaml`, `helm upgrade --install` idempotency, `helm rollback` for instant reversion, and `helm status` for release tracking.

---

**Q17. What is the difference between `helm install` and `helm upgrade --install`?**

> `helm install` fails if a release with that name already exists. `helm upgrade --install` performs an install if no release exists, or an upgrade if one does. This is idempotent — the same command works in a fresh environment and in a CI/CD pipeline that runs repeatedly. All my CI scripts use `helm upgrade --install` for this reason.

---

**Q18. How do you use `values.yaml` to manage environment-specific configuration?**

> `values.yaml` holds default values. Environment-specific overrides are applied at deploy time: `helm install -f values-prod.yaml` or individual `--set key=value` flags. In `git-argo`, the key override is `image.tag` — this is what Argo CD changes when Stage 5 of the CI pipeline updates `values.yaml`. The Helm chart's `deployment.yaml` template references `{{ .Values.image.tag }}`, so changing this one field in `values.yaml` is the entire mechanism for deploying a new version.

---

## Git & GitLab CI/CD

**Q19. What is the difference between `git revert` and `git reset` for rollback?**

> `git reset` rewrites history — it moves the branch pointer backward and can discard commits. This is destructive to shared branches and forces everyone else to re-sync. `git revert` creates a new commit that undoes the changes of a previous commit, preserving the full history. In a GitOps context, `git revert` is mandatory — Argo CD tracks commits; rewriting history with reset causes unpredictable reconciliation behavior. When I rolled back from v2.0.0 to v1.0.0, I ran `git revert a702fba`, which created commit `9f8c045` restoring `values.yaml` to `tag: v1.0.0`. Argo CD then saw a new commit, reconciled, and rolled back cleanly.

---

**Q20. What is `[skip ci]` in a Git commit message and why is it essential in a GitOps pipeline?**

> `[skip ci]` is a convention recognized by most CI/CD platforms to suppress pipeline triggering on that commit. In my pipeline, Stage 5 (`promote-gitops`) commits a change to GitHub and pushes it. Without `[skip ci]`, this commit would trigger another GitHub Actions run (if configured) or cause re-triggering issues. More critically — if the GitOps configuration were also the CI pipeline source, it would create an infinite loop: pipeline runs → updates values.yaml → triggers pipeline → updates values.yaml → ...

---

**Q21. Explain what `CI_COMMIT_SHORT_SHA` is and why you use it for image tagging instead of `latest`.**

> `CI_COMMIT_SHORT_SHA` is a GitLab predefined variable set to the first 8 characters of the git commit SHA that triggered the pipeline. Using it as the image tag creates immutable, traceable image identifiers: `registry.gitlab.com/supravatdash7399/git-argo:9dbdf50d` unambiguously identifies the exact source code version. `latest` is mutable — it moves with every push — which means you can't tell from the tag alone what code is running, and a rollback by tag is impossible. With SHA tags, rollback is `git revert` → new SHA → update `values.yaml` → Argo CD pulls the previous SHA-tagged image.

---

**Q22. Walk me through the YAML colon-parser failure in your GitLab pipeline and how you fixed it.**

> In my `.gitlab-ci.yml`, I had a script line:
> ```yaml
> - echo "==> Building Docker image tagged with commit SHA: ${IMAGE_TAG}..."
> ```
> The GitLab CI YAML parser treated the string as a mapping key — the colon after `SHA` followed by content looked like `key: value` syntax. The pipeline refused to even start, failing at YAML parsing before any job ran.
>
> The fix was to wrap the entire echo string in single quotes at the YAML level:
> ```yaml
> - 'echo "==> Building Docker image tagged with commit SHA: ${IMAGE_TAG}..."'
> ```
> Single quotes in YAML mean "treat this as a literal string, no YAML interpretation." The shell still interprets the double-quoted inner string and expands `${IMAGE_TAG}`. I applied this fix to every echo statement containing a colon in the pipeline. Committed as `1fda3f5`.

---

**Q23. Walk me through the alpine/git entrypoint issue in Stage 5 and how you resolved it.**

> Stage 5 uses `alpine/git:2.45.2` as the Docker image. The pipeline failed with:
> ```
> git: 'sh' is not a git command
> ```
> The root cause: `alpine/git` sets `ENTRYPOINT ["/usr/bin/git"]`. When GitLab CI runs a job with this image, it prepends `sh -c` to execute the script. So the actual container command was `git sh -c "echo ..."` — passing `sh` as a git subcommand, which doesn't exist.
>
> Fix: add `entrypoint: [""]` to the job's image definition:
> ```yaml
> image:
>   name: alpine/git:2.45.2
>   entrypoint: [""]
> ```
> This overrides the image's entrypoint with an empty array, so GitLab CI's injected shell runs directly: `sh -c "echo ..."`. Committed as `9dbdf50`.

---

**Q24. What is a JUnit XML report and how does GitLab CI use it?**

> JUnit XML is a standard test results format originally from Java's JUnit framework, now supported by virtually every test runner. Pytest generates it with `--junitxml=report.xml`. GitLab CI ingests it via:
> ```yaml
> artifacts:
>   reports:
>     junit: junit-report.xml
> ```
> GitLab parses the XML and displays per-test pass/fail results directly in the merge request UI, with failure details inline. It also enables trend tracking across pipeline runs. I export the report as a 7-day artifact so previous test results remain accessible for debugging.

---

## GitOps & Argo CD

**Q25. What is GitOps and how is it different from traditional CI/CD push-based deployment?**

> Traditional CI/CD push-based deployment: the pipeline runs `kubectl apply` or `helm install` directly against the cluster from the CI system. The pipeline has cluster credentials, it pushes changes to the cluster.
>
> GitOps: the pipeline only updates the Git repository. A controller (Argo CD) running inside the cluster continuously pulls the desired state from Git and reconciles it with the live cluster state. The cluster has outbound access to Git — not the other way around. Benefits: audit trail (Git history is the deployment log), drift detection (controller sees any divergence from Git), easy rollback (revert a Git commit), and no cluster credentials in CI.

---

**Q26. What does Argo CD's `selfHeal: true` policy do and when does it activate?**

> `selfHeal: true` means the Argo CD Application Controller automatically revertes any live cluster state that diverges from the Git-defined desired state — without waiting for a human to click "Sync." It activates whenever the controller detects `OutOfSync` status.
>
> Demonstrated in my project: I ran `kubectl scale deployment gitops-demo --replicas=3`. Within seconds, Argo CD detected the live replica count (3) differed from Git desired count (1). With `selfHeal: true`, it immediately issued a Sync operation, terminated the 2 extra pods, and returned the deployment to 1 replica. The event log showed `Auto Heal Attempts Count: 1`.

---

**Q27. How does Argo CD determine what to deploy — what is an Application CR?**

> An Application is an Argo CD Custom Resource that defines:
> - **Source**: Git repository URL, revision (branch/tag/SHA), path within the repo
> - **Destination**: Kubernetes cluster API server URL and namespace
> - **Sync policy**: manual or automated, selfHeal, prune orphaned resources
>
> My `argocd/application.yaml`:
> ```yaml
> spec:
>   source:
>     repoURL: https://github.com/SUPRAVAT001/git-argo.git
>     targetRevision: HEAD
>     path: helm/gitops-demo
>   destination:
>     server: https://kubernetes.default.svc
>     namespace: gitops-demo
>   syncPolicy:
>     automated:
>       prune: true
>       selfHeal: true
> ```
> Argo CD polls this GitHub repo (or receives a webhook) and applies the Helm chart at `helm/gitops-demo` to the `gitops-demo` namespace when it detects drift.

---

**Q28. What is the difference between Argo CD `Synced` and `Healthy` status?**

> These are independent status dimensions:
> - **Sync status**: Does the live cluster state match the desired Git state? `Synced` = yes, `OutOfSync` = no.
> - **Health status**: Are the deployed resources functioning correctly? `Healthy` = Deployment has minimum replicas available, pods are Running and Ready. `Degraded` = pods failing, `Progressing` = rolling update in progress.
>
> You can be `Synced` but `Degraded` (Git state applied successfully, but pods are crashing). You can be `OutOfSync` but `Healthy` (drift detected, but current workload is still running fine). The ideal state is `Synced` + `Healthy`.

---

**Q29. How does Argo CD handle image pull from a private registry?**

> Argo CD itself doesn't pull images — it's the kubelet that does. Argo CD applies the Kubernetes manifests; the kubelet then pulls the image. For a private registry, you need an `imagePullSecret` — a Kubernetes Secret of type `docker-registry` containing the registry credentials. The Secret is referenced in the pod's `spec.imagePullSecrets`. In my project, `gitops-demo` pods pull from `registry.gitlab.com` — a private GitLab Container Registry. This required creating an `imagePullSecret` from GitLab registry credentials and referencing it in the Helm values.

---

## Prometheus, Grafana & Alertmanager

**Q30. Explain the Prometheus data model: what is a metric, label, and time series?**

> A Prometheus metric is a named measurement with optional labels (key-value pairs). Each unique combination of metric name + label set defines a time series — a sequence of `(timestamp, float64)` data points stored in the TSDB.
>
> Example from my FastAPI app:
> ```
> app_http_requests_total{method="GET",endpoint="/health",status="200"} 42
> ```
> `app_http_requests_total` is the metric name. `{method="GET",endpoint="/health",status="200"}` is the label set. This creates one time series. If the app also serves `/metrics` and `/version`, there are 3 separate time series for `app_http_requests_total`. PromQL uses label matchers (`{endpoint="/health"}`) to select and aggregate across these.

---

**Q31. What is the difference between a Prometheus counter, gauge, and histogram?**

> - **Counter**: Monotonically increasing (only goes up or resets to 0 on restart). Used for requests, errors, bytes processed. Use `rate()` or `increase()` in PromQL to get the rate of change. `app_http_requests_total` in my app is a counter.
> - **Gauge**: Can go up or down — represents a current value. Used for memory usage, active connections, queue depth. `app_uptime_seconds` starts as a gauge (though it's monotonically increasing, it represents a current state).
> - **Histogram**: Samples observations into configurable buckets. Automatically creates `_bucket`, `_sum`, `_count` time series. Used for request latencies — allows calculating percentiles (p50, p95, p99).

---

**Q32. How does Alertmanager decide where to route an alert?**

> Alertmanager uses a routing tree defined in its configuration. The root route has a default receiver. Child routes have label matchers — if an incoming alert's labels match a route's matchers, Alertmanager sends it to that route's receiver (email, Slack, PagerDuty, webhook, etc.). Routes can also define `group_by` (batch similar alerts), `group_wait` (delay before sending first notification to allow more alerts to group), and `repeat_interval` (how often to re-notify for ongoing alerts).
>
> In `kube-obs`, alerts fire from Prometheus rules (e.g., `InstanceDown`, `HighMemoryUsage`) with labels like `severity: critical`. The Alertmanager routing tree matches on these labels and dispatches to the configured webhook receiver.

---

**Q33. What is a PromQL rate() function and when do you use it?**

> `rate(counter[window])` calculates the per-second average rate of increase of a counter over the given time window. It automatically handles counter resets (application restarts). Use it on counters — never on gauges.
>
> Example: `rate(app_http_requests_total{endpoint="/health"}[5m])` gives requests per second to the `/health` endpoint, averaged over the last 5 minutes. This is useful in Grafana for a "request rate" panel. Without `rate()`, the raw counter value is just an ever-increasing number that tells you little about current load.

---

## SRE Fundamentals

**Q34. What is an SLO and how would you define one for the gitops-demo application?**

> An SLO (Service Level Objective) is a target for a service level indicator (SLI). An SLI measures a specific reliability dimension (availability, latency, error rate). The SLO is a threshold that must be met over a time window.
>
> For `gitops-demo`, if it were a real service:
> - **Availability SLO**: 99.5% of requests to `/health` return 2xx within 30 days
> - **Latency SLO**: 95% of `/version` requests complete within 200ms
>
> These would be measured from Prometheus metrics: `app_http_requests_total{status="200"}` / `app_http_requests_total` for availability; a histogram metric for latency. Error budgets follow: a 99.5% availability SLO allows 0.5% errors = ~3.6 hours downtime per month.

---

**Q35. What is the difference between horizontal and vertical scaling, and which is preferred for stateless workloads?**

> **Horizontal scaling (scale out)**: Add more pod replicas. Each handles a portion of traffic. The load balancer (Kubernetes Service) distributes requests across all replicas. Requires the application to be stateless — no session affinity, no local state that isn't shared.
>
> **Vertical scaling (scale up)**: Give existing pods more CPU/memory (increase resource limits). Has an upper bound (node capacity), requires a pod restart to apply, and creates a single point of failure if only one replica exists.
>
> For stateless workloads like `gitops-demo` (FastAPI with no local state), horizontal scaling is preferred. Combined with a Kubernetes Horizontal Pod Autoscaler (HPA) watching CPU metrics, the cluster can scale automatically within defined min/max replica bounds.

---

**Q36. What is a Kubernetes resource request vs. limit and what happens when each is exceeded?**

> **Request**: the minimum guaranteed resources for scheduling. The scheduler only places a pod on a node with at least this much allocatable capacity. If a pod uses less than its request, it still "owns" that capacity from the scheduler's perspective.
>
> **Limit**: the maximum the container is allowed to consume. For CPU: if the process tries to use more than the limit, the kernel throttles it (CFS quota) — no OOM kill, just slower execution. For memory: if the process exceeds the limit, the kernel OOM killer terminates the container, and Kubernetes restarts it (resulting in an OOMKilled event).
>
> My `gitops-demo` values: requests `50m CPU / 64Mi RAM`, limits `200m CPU / 128Mi RAM`. This means: the FastAPI app is guaranteed 50 millicores and can burst to 200m before being throttled.

---

## Project-Specific Scenarios

**Q37. Walk me through how a developer's code push reaches a running Kubernetes pod in your git-argo project — step by step.**

> 1. Developer pushes to `supravatdash7399/git-argo` on GitLab.
> 2. GitLab detects the push to `main` and triggers pipeline #N.
> 3. **Stage 1 (validate)**: Python syntax check (`py_compile`), YAML structural validation, `helm lint` — all pass on `python:3.12-slim`.
> 4. **Stage 2 (test)**: Pytest executes 6 test cases on the FastAPI endpoints using `TestClient`. JUnit XML uploaded as artifact.
> 5. **Stage 3 (build)**: `docker:27-cli` with `docker:27-dind` service. Docker builds a multi-stage image tagged with `${CI_COMMIT_SHORT_SHA}` (e.g., `9dbdf50d`). Image saved to `image.tar` artifact.
> 6. **Stage 4 (publish)**: Loads `image.tar`, authenticates to `registry.gitlab.com`, pushes `:9dbdf50d` and `:latest`.
> 7. **Stage 5 (update-gitops)**: Clones `github.com/SUPRAVAT001/git-argo.git` using `GITOPS_GITHUB_TOKEN`, runs `sed` to update `image.repository` and `image.tag` in `helm/gitops-demo/values.yaml`, commits with `[skip ci]`, pushes to `main`.
> 8. GitHub `main` now has commit `a58cf62` authored by GitLab CI/CD Bot.
> 9. Argo CD polls GitHub (every 3 min), detects the new commit, sees `values.yaml` changed.
> 10. Argo CD renders the Helm chart with the new tag, compares to live cluster state → `OutOfSync`.
> 11. Automated sync initiates: Argo CD applies the new Deployment via `kubectl apply`.
> 12. Kubernetes performs rolling update: new pod scheduled, pulls image from GitLab Registry, liveness/readiness probes pass.
> 13. Old pod terminated. Service routes to new pod. `/version` now returns `9dbdf50d`.
> Total pipeline time: ~3 minutes 7 seconds (Pipeline #3045047835).

---

**Q38. How did you recover Minikube after it entered NotReady state due to WSL2 swap exhaustion?**

> The root cause was WSL2 swap exhaustion — with insufficient virtual memory, Minikube's containerd and etcd processes were OOM-killed, causing the node to drop to NotReady.
>
> Recovery steps:
> 1. Identified the issue via `free -h` (swap fully consumed) and `docker ps` (Minikube container unhealthy).
> 2. Increased WSL2 memory: edited `%USERPROFILE%\.wslconfig` to allocate 4 GB RAM and 2 GB swap, then `wsl --shutdown` and restarted WSL2.
> 3. With more memory available: `minikube start --profile minikube` resumed the existing cluster (did not recreate it — preserved all existing PVCs and namespaces).
> 4. Verified: node returned to Ready, all namespaces (`argocd`, `gitops-demo`, `observability`) came back healthy.
> 5. Verified kube-obs stack: all 8 observability pods running.
>
> Lesson: in a resource-constrained environment, always set explicit memory limits on Minikube (`--memory`) and monitor WSL2 memory via `free -h`.

---

**Q39. How did you demonstrate Argo CD self-healing and what did the evidence look like?**

> I ran `kubectl scale deployment gitops-demo -n gitops-demo --replicas=3` while Argo CD was watching. The sequence:
>
> 1. `kubectl get deployment` immediately showed 3/3 READY replicas.
> 2. Within seconds, Argo CD UI showed the application status flip from `Synced` to `OutOfSync` with the drift explanation: live replicas (3) vs. desired in Git (1).
> 3. With `selfHeal: true`, Argo CD initiated a sync automatically — no human action.
> 4. `kubectl get pods -n gitops-demo` showed 2 pods transitioning to Terminating.
> 5. Within 10-15 seconds: back to 1 pod Running and Ready.
> 6. Argo CD returned to `Synced` + `Healthy`.
> 7. Event log: `Auto Heal Attempts Count: 1`.
>
> Evidence is captured in screenshot `04_argocd_drift_detected.png` (OutOfSync) and `05_argocd_self_healing.png` (event log with auto-heal confirmation).

---

**Q40. If you were to extend the git-argo project for a team environment, what would you add?**

> Without claiming production readiness, the natural extensions would be:
> 1. **Argo CD Image Updater**: eliminate Stage 5 entirely — Argo CD polls the registry directly and commits the tag update automatically.
> 2. **Multiple environments**: separate `values-staging.yaml` and `values-prod.yaml` with Argo CD ApplicationSets managing deployment across environments.
> 3. **Network Policies**: restrict pod-to-pod communication within namespaces to minimum required paths.
> 4. **Secrets management**: replace hardcoded env vars with External Secrets Operator pulling from Vault or AWS Secrets Manager.
> 5. **Merge request previews**: Argo CD `ApplicationSet` with PR generator creating ephemeral preview environments per merge request.
> 6. **Monitoring integration**: connect `/metrics` from `gitops-demo` to the `kube-obs` Prometheus instance with alerting rules for HTTP error rates.

---

## Governed AI Systems & Distributed Control Planes (DevOps Jarvis)

**Q41. What is "Governed Bounded Autonomy" and why is it essential when integrating AI into infrastructure operations?**

> Giving Large Language Models direct shell access or cluster credentials creates catastrophic operational risk due to prompt injection, model hallucinations, or non-deterministic reasoning.
>
> In DevOps Jarvis, I implemented **Governed Bounded Autonomy**: LLMs extract natural language intent, correlate observability metrics, and synthesize remediation strategies, but are architecturally barred from directly mutating infrastructure. All proposed actions must pass through an immutable choke point: the `ExecutionController`. This controller enforces four deterministic gates: declarative OPA/Rego policies, an algorithmic blast-radius risk scoring engine, a dry-run simulation checking preconditions, and human approval gates for high-risk mutations. If any gate fails, the mutation is rejected before it touches the cluster.

---

**Q42. How does Open Policy Agent (OPA) integrate into your autonomous control plane?**

> OPA runs as an independent policy evaluation engine using the Rego declarative policy language. Before the `ExecutionController` actuates any Kubernetes change, it translates the proposed intent into a structured JSON query document and passes it to OPA.
>
> The Rego policies enforce non-negotiable organizational rules:
> - Forbidding mutating production during defined freeze windows.
> - Rejecting workloads that attempt to run as root (`runAsUser: 0`).
> - Blocking modifications to reserved cluster namespaces (`kube-system`, `argocd`, `observability`).
> - Enforcing resource limit declarations on all containers.
> Because OPA evaluates deterministically outside the LLM, the model cannot hallucinate or bypass policy constraints.

---

**Q43. Explain the epistemic invariants `UNKNOWN != SAFE` and `STALE != FRESH` in automated progressive delivery.**

> When an autonomous loop executes multi-stage canary traffic promotions (10% → 25% → 50% → 100%), it must evaluate live telemetry from Prometheus. A naive implementation checks if `error_rate < 1%` and advances. But if Prometheus is unreachable, or scraping is lagging, the query might return 0 errors simply because data is missing.
>
> I implemented two strict epistemic invariants in `CanaryEvaluator`:
> - **`UNKNOWN != SAFE`**: If metrics are missing, Prometheus returns empty vectors, or sample counts are insufficient, the system treats this as an unsafe state and immediately halts promotion. Absence of evidence is not evidence of absence.
> - **`STALE != FRESH`**: If the timestamp of the latest metric sample is older than the freshness threshold (e.g., 60s), the system pauses progression. Telemetry must be demonstrably fresh before traffic weight increases.

---

**Q44. How do you prevent split-brain mutations in distributed workers executing infrastructure operations?**

> When multiple workers or async event loops operate on the same infrastructure, race conditions can cause split-brain mutations.
>
> In DevOps Jarvis (Milestone 9 Phase 2), I implemented a two-part concurrency guard:
> 1. **PostgreSQL Row-Level Leases**: Workers must acquire an execution lease inside a database transaction using `SELECT ... FOR UPDATE` with a strictly bounded time-to-live (TTL). Only one worker can hold the lease for a given target resource at a time.
> 2. **Monotonic Fencing Tokens**: Every lease acquisition increments a monotonic integer token. If Worker A acquires lease token #5, but experiences a network partition or stop-the-world GC pause, its lease expires. Worker B acquires the lease with token #6 and completes the task. When Worker A wakes up and attempts to commit its mutation, the database rejects the write because token #5 is superseded by token #6.

---

**Q45. How does a self-healing reconciliation loop handle an interrupted workflow without human intervention?**

> If the control plane process crashes or the node reboots midway through a multi-stage canary rollout, the workflow state in the database might be left as `IN_PROGRESS`.
>
> In Milestone 9 Phase 3, I implemented an autonomous reconciliation loop that fires on startup and during periodic background ticks:
> 1. It scans PostgreSQL for active tasks with expired execution leases.
> 2. Instead of blindly retrying or failing the task, it performs an **authoritative cluster readback**: it queries the live Kubernetes API and NGINX Ingress rules to discover the actual cluster state (e.g., did the 25% canary traffic split actually apply before the crash?).
> 3. It reconciles the database task state with the physical reality of the cluster.
> 4. If the cluster is healthy and safe, it resumes the rollout loop from the exact verified stage without requiring an external user prompt.

---

> **Study note**: Practice explaining the git-argo pipeline failure scenarios out loud — interviewers strongly value engineers who can articulate real debugging experiences with root cause analysis, not just describe happy-path implementations.

