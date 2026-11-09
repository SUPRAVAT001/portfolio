# Real-World Troubleshooting Scenarios & Post-Mortems

First-principles debugging logs, root cause analyses (RCA), and remediation procedures from actual engineering execution across all three platforms.

---

## Scenario 1: Minikube Cluster Recovery from WSL2 Swap Exhaustion

### 1. Incident Overview
* **Environment**: Local Minikube v1.35.1 on WSL2 Ubuntu Linux (kernel 6.6+).
* **Workloads Impacted**: Argo CD, `gitops-demo`, and `kube-obs` telemetry stack.
* **Symptom**: Minikube entered `NotReady` status. `kubectl` commands returned `connection refused` on `127.0.0.1:8443`. Docker daemon reported container `minikube` in unhealthy state.

### 2. Root Cause Analysis (RCA)
* Inspection of system metrics using `free -h` revealed total physical RAM utilization at 4.2 GiB out of 4.3 GiB, and swap space completely exhausted (0 bytes available).
* Under intense concurrent memory pressure from running Prometheus TSDB, Grafana, Argo CD controllers, and multiple FastAPI pods, the Linux kernel Out-Of-Memory (OOM) killer invoked `oom_kill_process`.
* Critical system daemons inside the Minikube container (`containerd` and `kube-apiserver`) were killed by the kernel, dropping the node to `NotReady` and terminating API server responsiveness.

### 3. Remediation & Recovery Runbook
1. **Host-Level Virtual Memory Expansion**:
   * Edited WSL2 host configuration (`%USERPROFILE%\.wslconfig`) to allocate 4.5 GiB RAM and explicitly expand swap space to 2.0 GiB:
     ```ini
     [wsl2]
     memory=4GB
     swap=2GB
     ```
   * Executed `wsl --shutdown` and relaunched Ubuntu to reinitialize memory boundaries.
2. **Safe Cluster Resumption**:
   * Rather than executing destructive commands (`minikube delete`), the cluster was safely resumed preserving all persistent volume claims and namespace state:
     ```bash
     minikube start --profile minikube
     ```
3. **Verification**:
   * Verified node returned to `Ready` status (`kubectl get nodes`).
   * Confirmed all 8 observability pods in `observability`, all 4 Argo CD pods in `argocd`, and the microservice in `gitops-demo` returned to healthy `Running` state without data loss.

---

## Scenario 2: GitLab CI YAML Parser Collision with Bash Colon Syntax

### 1. Incident Overview
* **Platform**: GitLab CI/CD SaaS Runner ([Pipeline #3044970789](https://gitlab.com/supravatdash7399/git-argo/-/pipelines/3044970789)).
* **Stage Impacted**: `build` (`build-image`).
* **Symptom**: Pipeline was rejected during initial syntax validation with a YAML mapping parse error before executing any container job.

### 2. Root Cause Analysis (RCA)
* The job script contained an unquoted log statement:
  ```yaml
  script:
    - echo "==> Building Docker image tagged with commit SHA: ${IMAGE_TAG}..."
  ```
* Under the YAML 1.2 specification, an unquoted string containing a colon followed by whitespace (`: `) is parsed as a dictionary key-value mapping delimiter. The GitLab parser attempted to treat `Building Docker image tagged with commit SHA:` as a mapping key, causing a fatal syntax failure.

### 3. Remediation
* Wrapped the entire echo expression in explicit outer single quotes at the YAML level:
  ```yaml
  script:
    - 'echo "==> Building Docker image tagged with commit SHA: ${IMAGE_TAG}..."'
  ```
* The single quotes instruct the YAML parser to treat the content as a raw scalar string, while the inner double quotes allow the POSIX shell inside the container to expand the environment variable `${IMAGE_TAG}`. Committed as `1fda3f5`.

---

## Scenario 3: `alpine/git` Docker Entrypoint Hijacking Shell Execution

### 1. Incident Overview
* **Platform**: GitLab CI/CD SaaS Runner ([Pipeline #3045017523](https://gitlab.com/supravatdash7399/git-argo/-/pipelines/3045017523)).
* **Stage Impacted**: Stage 5 (`promote-gitops`).
* **Symptom**: Job failed within 1 second with error: `git: 'sh' is not a git command. See 'git --help'`.

### 2. Root Cause Analysis (RCA)
* Stage 5 uses the lightweight container image `alpine/git:2.45.2` to execute Git operations without installing Git on a heavy generic image.
* The official `alpine/git` Dockerfile defines `ENTRYPOINT ["/usr/bin/git"]`.
* When GitLab CI executes a job script, it automatically generates a wrapper script and executes the container by invoking `sh -c "<gitlab-script-wrapper>"`.
* Because `ENTRYPOINT` was configured to `git`, the executed command became:
  ```bash
  /usr/bin/git sh -c "..."
  ```
* Git interpreted `sh` as a git subcommand (like `git status` or `git commit`) and aborted immediately.

### 3. Remediation
* In `.gitlab-ci.yml`, overrode the image entrypoint to an empty list:
  ```yaml
  promote-gitops:
    stage: update-gitops
    image:
      name: alpine/git:2.45.2
      entrypoint: [""]
  ```
* This cleared the entrypoint, allowing GitLab's runner to invoke `sh` directly as the primary executable. Committed as `9dbdf50`.

---

## Scenario 4: Pre-Deployment Registry Divergence Prevention

### 1. Incident Overview
* **Stage**: Stage 5 (`promote-gitops`) pipeline code review before initial production run.
* **Risk**: High probability of triggering `ImagePullBackOff` during Kubernetes rollout.

### 2. Root Cause Analysis (RCA)
* The default `helm/gitops-demo/values.yaml` contained:
  ```yaml
  image:
    repository: gitops-demo
    tag: v1.0.0
  ```
* Stage 5 was initially coded to update only the `tag` field:
  ```bash
  sed -i -E "s/(tag: \")[^\"]+(\")/\1${IMAGE_TAG}\2/" values.yaml
  ```
* In local Minikube testing, `image.repository: gitops-demo` worked because the image was loaded directly into Minikube's Docker daemon cache.
* However, in the hosted cloud workflow, the newly built image was published to `registry.gitlab.com/supravatdash7399/git-argo`.
* If Stage 5 only updated `tag: 9dbdf50d`, Kubernetes would attempt to pull `docker.io/library/gitops-demo:9dbdf50d`, resulting in an immediate `ImagePullBackOff` failure in production.

### 3. Remediation
* Updated Stage 5 `sed` operations to programmatically update both `repository:` and `tag:`:
  ```bash
  sed -i -E "s|^([[:space:]]*repository:).*|\1 ${CI_REGISTRY_IMAGE}|" ${HELM_PATH}/values.yaml
  sed -i -E "s/(tag: \")[^\"]+(\")/\1${IMAGE_TAG}\2/" ${HELM_PATH}/values.yaml
  ```
* Committed as `2376a62`. When the pipeline ran, Kubernetes received the fully qualified GitLab registry path and pulled the image cleanly.

---

## Scenario 5: Argo CD Out-of-Band Drift Remediation

### 1. Incident Overview
* **Objective**: Validate automated self-healing against unauthorized cluster mutations.
* **Action**: Imperative mutation executed out-of-band:
  ```bash
  kubectl scale deployment gitops-demo -n gitops-demo --replicas=3
  ```

### 2. Observation & Controller Reaction
1. `kubectl get deployment` temporarily showed 3 available replicas.
2. Argo CD Application Controller detected the live state divergence from the Git-defined baseline (`replicaCount: 1`).
3. Application health state immediately flipped from `Synced` to `OutOfSync`.
4. Because `syncPolicy.automated.selfHeal: true` was configured, Argo CD initiated an automatic remediation sync without human intervention.
5. Within 15 seconds, Argo CD enforced the Git desired state: terminated the two rogue pods and returned the deployment to `1/1 Ready`.
6. Event log recorded: `Auto Heal Attempts Count: 1`. Captured in screenshot [`05_argocd_self_healing.png`](../evidence/git-argo/05_argocd_self_healing.png).

---

## Scenario 6: Declarative Git Revert Rollback vs. Imperative Rollout Undo

### 1. Incident Overview
* **Objective**: Rollback application from `v2.0.0` back to `v1.0.0` with zero downtime.

### 2. Analysis of Imperative vs. Declarative Approaches
* **Imperative Approach (`kubectl rollout undo`)**:
  * Modifies cluster state directly.
  * In a GitOps architecture, this triggers an immediate conflict: Argo CD detects cluster state differing from Git and automatically "heals" the cluster back to `v2.0.0`, undoing the engineer's rollback!
* **Declarative GitOps Approach (`git revert`)**:
  * Preserves immutable audit history by creating a new Git commit:
    ```bash
    git revert a702fba -m "revert: rollback release to v1.0.0"
    git push origin main
    ```
  * Argo CD detects commit `9f8c045` on `origin/main`.
  * Renders `values.yaml` (`tag: v1.0.0`), initiates a rolling update in Kubernetes, and restores the stable version with zero downtime. Captured in screenshot [`06_gitops_git_rollback.png`](../evidence/git-argo/06_gitops_git_rollback.png).

---

## Scenario 7: DevOps Jarvis Distributed Lease Expiration & Fencing Protection

### 1. Incident Overview
* **Domain**: Distributed concurrency in autonomous SRE control planes (Milestone 9 Phase 2).
* **Failure Mode**: Network partition or long Garbage Collection pause causing worker zombie states.

### 2. Protection Mechanism
* Worker 1 acquires an execution lease for `canary-rollout-service-a` in PostgreSQL using `SELECT ... FOR UPDATE` with a 30-second TTL and receives monotonic fencing token `101`.
* Worker 1 undergoes a 45-second network partition. Its lease expires in the database.
* Worker 2 scans for expired leases, claims the task, increments the fencing token to `102`, and completes the traffic shift.
* Worker 1 recovers and attempts to commit its cached mutation using fencing token `101`.
* The database constraint / validation layer checks:
  ```sql
  UPDATE execution_leases SET status = 'COMPLETED' WHERE id = :id AND fencing_token = :token;
  ```
* Because `fencing_token` is now `102`, Worker 1's update matches 0 rows. The transaction aborts, preventing Worker 1 from overwriting Worker 2's fresh state.

