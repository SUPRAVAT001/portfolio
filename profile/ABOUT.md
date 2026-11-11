# About — Supravat Dash

DevOps, Cloud, and Platform Engineer focused on Kubernetes infrastructure, declarative continuous delivery, full-stack observability, and governed infrastructure automation.

- **GitHub**: [github.com/SUPRAVAT001](https://github.com/SUPRAVAT001)
- **GitLab**: [gitlab.com/supravatdash7399](https://gitlab.com/supravatdash7399)

---

## Engineering Background & Approach

I build reproducible, observable, and policy-governed cloud-native systems from first principles. Across my independent engineering work, I focus on eliminating manual operational toil and enforcing clear boundaries between build pipelines, declarative configuration, and cluster execution:

* **Observability Before Scale**: Instrumentation, metric discovery (`ServiceMonitor`), alert lifecycle validation, and dashboard-as-code provisioning.
* **Declarative Over Imperative**: Treating Git as the single source of truth for cluster state using Helm and Argo CD rather than ad-hoc `kubectl` mutations.
* **Least Privilege by Default**: Running application containers as non-root (`UID 10001`), dropping Linux capabilities (`ALL`), disabling unnecessary Kubernetes ServiceAccount token automounts, and masking CI tokens.
* **Governed Automation**: Designing deterministic safety boundaries—policy-as-code (OPA), blast-radius risk checks, distributed lease locking, and fail-closed telemetry gates—around autonomous infrastructure workflows.

---

## Scope of Experience & Credibility

All work presented in this portfolio reflects **independently designed, built, and verified engineering platforms** rather than commercial enterprise deployments:

* **`kube-obs` & `git-argo`** run on a resource-constrained single-node Minikube cluster (Kubernetes v1.35.1 on WSL2 Ubuntu), integrated with hosted GitLab SaaS CI/CD and GitHub.
* **`devops-jarvis`** is an actively developed control plane validated through a 1,419-test automated suite and live integration runs against Minikube (`v1.35.0` / Kubernetes `v1.32.0`), PostgreSQL 17, and OPA (`0.68.0`).

I clearly separate technologies **implemented and verified in running code** from concepts **studied for future public cloud adoption** (AWS EKS, Terraform, and distributed tracing). See [Technical Skills](TECHNICAL_SKILLS.md) for the exact breakdown.

