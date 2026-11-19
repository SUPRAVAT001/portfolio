# Production Deployment Report: `veyrion.in`
**Deployment Target:** Oracle Cloud Infrastructure (OCI) Compute Instance  
**Instance Name:** `instance-20261115-1749` (`VM.Standard.E2.1.Micro`)  
**Public IP:** `140.238.230.200` | **Private IP:** `[REDACTED_INTERNAL_IP]`  
**Production Domain:** `veyrion.in` (Canonical Apex) & `www.veyrion.in` (Canonical 301 Redirect)  
**Deployment Date & Time:** 2026-11-19 12:24:30 GMT  
**Deployment Status:** **SUCCESSFULLY DEPLOYED & OPERATIONAL**  
**Lead Engineer:** Senior Linux Systems Engineer, Cloud Infrastructure Security Engineer, & Production SRE  

---

## 1. Executive Summary

The personal engineering portfolio for **Supravat Dash** has been successfully deployed and published to production under the canonical domain **`https://veyrion.in/`**.

The deployment was executed on the target Oracle Cloud Infrastructure (OCI) Always-Free compute instance using the pre-audited standalone Caddy web server architecture. In accordance with strict production restrictions, **zero package managers (`dnf`/`yum`) and zero container engines (Docker/Podman)** were utilized, ensuring complete stability and protecting against memory exhaustion on the 1.0 GB RAM host.

Both root domain (`veyrion.in`) and subdomain (`www.veyrion.in`) are secured with official, publicly trusted **Let's Encrypt TLS certificates** (TLSv1.3 with HTTP/2 and HTTP/3 support). Insecure HTTP requests automatically redirect to HTTPS, and requests to `www.veyrion.in` permanently redirect (301) to the canonical apex `https://veyrion.in/`.

All 294 internal links, static case studies, resume PDF, proof screenshots, stylesheets, scripts, and custom 404 error boundaries have been empirically tested and verified in production.

---

## 2. Server & Environment Information

* **Server Hostname:** `instance-20261115-1749`
* **Operating System:** Oracle Linux Server release 9.8
* **Linux Kernel:** `6.12.0-207.111.5.6.el9uek.x86_64` (Oracle Unbreakable Enterprise Kernel - UEK)
* **Architecture:** `x86_64`
* **CPU Model:** AMD EPYC 7551 32-Core Processor (1 Core, 2 vCPUs allocated)
* **Total Host Physical RAM:** 945 MiB (~1.0 GB)
* **Available Host RAM (Post-Deployment):** **301 MiB** (Ample safety margin)
* **Root Disk Free Space:** **24 GiB** (20% disk utilization; 80% free)
* **SELinux Mode:** `Enforcing` (targeted policy)
* **Web Server:** Caddy Standalone Linux AMD64
* **Caddy Version:** **`v2.11.9 h1:bhZtcRKQOq0fuLvEgCdPYvUxXyGn9kzjG4lh2332DTE=`**
* **Caddy Binary Location:** `/usr/local/bin/caddy` (Mode `0755`, owned by `root:root`)
* **Dedicated Service User:** `caddy` (System account, `/sbin/nologin`, UID 987, GID 989)
* **Webroot Path:** `/var/www/veyrion.in` (Owned by `opc:caddy`, Mode `0755` dirs, `0644` files)

---

## 3. DNS Verification Results

Prior to certificate issuance, DNS resolution was empirically verified across global authoritative and public resolvers:

| Domain Name | Record Type | Target / Value | TTL | Verification Status |
| :--- | :--- | :--- | :--- | :--- |
| **`veyrion.in`** | `A` | `140.238.230.200` | 14,400s (4 hours) | **VERIFIED (Google 8.8.8.8, Cloudflare 1.1.1.1, and OCI Host)** |
| **`www.veyrion.in`** | `CNAME` | `veyrion.in.` $\rightarrow$ `140.238.230.200` | 14,400s (4 hours) | **VERIFIED (Google 8.8.8.8, Cloudflare 1.1.1.1, and OCI Host)** |

---

## 4. TLS / HTTPS Certificate Details

Let's Encrypt ACME automated validation succeeded seamlessly via multi-perspective global challenges:

* **Primary Domain:** `veyrion.in`
* **Subject Alternative Name (SAN):** `www.veyrion.in`
* **Certificate Authority (CA):** Let's Encrypt (`acme-v02.api.letsencrypt.org-directory`)
* **ACME Account ID:** `https://acme-v02.api.letsencrypt.org/acme/acct/4017829842`
* **Contact Email:** `supravatdash7399@gmail.com`
* **Certificate Serial / URL:** `https://acme-v02.api.letsencrypt.org/acme/cert/069a21b6c974d39ce4f58504182946bc2ab6`
* **Validity Period:** Nov 19, 2026 to Feb 17, 2027 (90-day standard ACME lifecycle)
* **TLS Negotiation:** `TLSv1.3` / `TLS_AES_128_GCM_SHA256` / `X25519MLKEM768`
* **Application Protocols (ALPN):** `h2` (HTTP/2), `h3` (HTTP/3 over QUIC)
* **Automated Renewal:** Managed autonomously in memory by Caddy 30 days prior to expiration.
* **Certificate Storage:** `/var/lib/caddy/.local/share/caddy/certificates/` (Permissions `0700`)

---

## 5. Systemd Service Status & Hardening

Caddy is registered and managed as a dedicated systemd service (`caddy.service`):

```
● caddy.service - Caddy Web Server
     Loaded: loaded (/etc/systemd/system/caddy.service; enabled; preset: disabled)
     Active: active (running) since Thu 2026-11-19 12:24:22 GMT; 3min ago
       Docs: https://caddyserver.com/docs/
   Main PID: 27363 (caddy)
      Tasks: 10 (limit: 64)
     Memory: 37.8M (high: 64.0M max: 128.0M available: 26.1M peak: 38.7M)
        CPU: 697ms
     CGroup: /system.slice/caddy.service
             └─27363 /usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
```

### Applied Sandboxing & Security Controls:
1. **Unprivileged Execution:** Runs as `caddy:caddy`.
2. **Linux Capabilities:** Granted `CAP_NET_BIND_SERVICE` ambient capability to bind ports 80 and 443 without root permissions.
3. **Cgroup Guardrails:** Memory usage is capped at `MemoryHigh=64M` and `MemoryMax=128M`. Current consumption is **~37.8 MiB**, safely below the threshold.
4. **Filesystem Isolation:** `ProtectSystem=full` mounts `/usr`, `/boot`, and `/etc` read-only. `ProtectHome=true` isolates user home directories.
5. **Sandboxing Flags:** `NoNewPrivileges=true`, `PrivateTmp=true`, `PrivateDevices=true`, `ProtectKernelTunables=true`, `ProtectKernelModules=true`, `ProtectControlGroups=true`, `RestrictRealtime=true`, `RestrictSUIDSGID=true`, `LockPersonality=true`.
6. **SELinux Contexts:**
   - Webroot files: `httpd_sys_content_t`
   - Access and error logs: `var_log_t`
   - Data & ACME cache: `var_lib_t`
   - Binary: `bin_t`

---

## 6. Host Firewall (Firewalld) Changes

Before applying rules, the pre-existing state was verified and preserved. The following selective adjustments were enacted:

* **Pre-Deployment Services:** `dhcpv6-client`, `ssh` (Ports 80 and 443 were blocked).
* **Added Services:** `http` (TCP 80), `https` (TCP 443).
* **Current Active Services:** `dhcpv6-client http https ssh`
* **SSH Port 22:** **Strictly untouched and fully active**.
* **Recorded State:** Stored in `[REDACTED_BACKUP_PATH]` for safe rollback tracking.

---

## 7. Comprehensive Website Verification Results

Every primary route, project case study, asset, and error boundary was tested against the live production server over HTTPS (`140.238.230.200`):

| Test Item | Production URL / Route | Protocol / Method | Expected Status | Result Status | Content Type & Details |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Homepage** | `https://veyrion.in/` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/html; charset=utf-8` (16,085 bytes) |
| **WWW Redirect** | `https://www.veyrion.in/` | `HTTP/2 GET` | 301 Moved | **301 Moved** | `Location: https://veyrion.in/` |
| **HTTP Upgrade** | `http://veyrion.in/` | `HTTP/1.1 GET` | 308 Permanent | **308 Permanent** | `Location: https://veyrion.in/` |
| **About Page** | `https://veyrion.in/about/` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/html; charset=utf-8` |
| **Projects Index** | `https://veyrion.in/projects/` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/html; charset=utf-8` |
| **DevOps Jarvis** | `https://veyrion.in/projects/devops-jarvis/` | `HTTP/2 GET` | 200 OK | **200 OK** | Flagship SRE case study live |
| **GitOps ArgoCD** | `https://veyrion.in/projects/git-argo/` | `HTTP/2 GET` | 200 OK | **200 OK** | GitOps case study live |
| **Kube Observability** | `https://veyrion.in/projects/kube-obs/` | `HTTP/2 GET` | 200 OK | **200 OK** | Kubernetes telemetry case study live |
| **TodoApp Study** | `https://veyrion.in/projects/todoapp/` | `HTTP/2 GET` | 200 OK | **200 OK** | FastAPI OCI case study live |
| **Contact Page** | `https://veyrion.in/contact/` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/html; charset=utf-8` |
| **Expertise Alias** | `https://veyrion.in/expertise/` | `HTTP/2 GET` | 200 OK | **200 OK** | Redirects to `/about/#capabilities` |
| **Engineering Alias**| `https://veyrion.in/engineering/` | `HTTP/2 GET` | 200 OK | **200 OK** | Redirects to `/about/` |
| **Resume PDF** | `https://veyrion.in/resume/Supravat_Dash_Resume.pdf` | `HTTP/2 GET` | 200 OK | **200 OK** | `application/pdf` (84,498 bytes) |
| **Custom 404** | `https://veyrion.in/nonexistent-route` | `HTTP/2 GET` | 404 Not Found| **404 Not Found** | Custom branded 404 template rendered |
| **Sitemap XML** | `https://veyrion.in/sitemap.xml` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/xml; charset=utf-8` (All 8 URLs veyrion.in) |
| **Robots TXT** | `https://veyrion.in/robots.txt` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/plain; charset=utf-8` |
| **Core CSS** | `https://veyrion.in/css/style.css` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/css; charset=utf-8` |
| **Homepage CSS** | `https://veyrion.in/css/homepage.css` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/css; charset=utf-8` |
| **Core JS** | `https://veyrion.in/js/main.js` | `HTTP/2 GET` | 200 OK | **200 OK** | `text/javascript; charset=utf-8` |
| **Profile Portrait** | `https://veyrion.in/images/profile.jpg` | `HTTP/2 GET` | 200 OK | **200 OK** | `image/jpeg` |
| **Project Proofs** | `https://veyrion.in/images/devops-jarvis/...` | `HTTP/2 GET` | 200 OK | **200 OK** | `image/png` |
| **External Demo** | `https://80-225-229-214.sslip.io/` | Link check | Preserved | **PRESERVED** | External link in case study untouched |

---

## 8. Defensive Security Headers Audit

Verified live on `https://veyrion.in/`:

```http
HTTP/2 200 
alt-svc: h3=":443"; ma=2592000
content-security-policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self';
permissions-policy: camera=(), microphone=(), geolocation=(), payment=(), usb=()
referrer-policy: strict-origin-when-cross-origin
strict-transport-security: max-age=86400
x-content-type-options: nosniff
x-frame-options: DENY
```
*Note on Fingerprinting:* The default `server: Caddy` response header has been successfully suppressed via `-Server`.

---

## 9. Resource Usage & System Health After Deployment

| Host Resource | Total Capacity | Post-Deployment Usage | Free / Available | Health Status |
| :--- | :--- | :--- | :--- | :--- |
| **Physical RAM** | 945 MiB | 644 MiB (all host daemons) | **301 MiB Available** | **EXCELLENT** (Zero swap thrashing) |
| **Caddy Process RSS** | Capped at 128M | **37.8 MiB** | 90.2 MiB cgroup headroom | **EXCELLENT** |
| **Root Disk** | 30 GiB | 5.8 GiB | **24 GiB Free (80%)** | **ABUNDANT** |
| **CPU Load** | 2 vCPUs | Load Avg: `0.08, 0.04, 0.01` | 98% CPU Idle | **IDLE** |
| **SSH Daemon** | Port 22 | PID 2096 active | Listening 0.0.0.0:22 | **HEALTHY** |
| **PCP Daemon** | Port 44321 | PID 2200 active | Loopback only | **HEALTHY** |
| **OCI Cloud Agent** | Management | Active (running) | Memory stable | **HEALTHY** |

---

## 10. Backup Location & Preserved State

A pre-deployment backup was automatically captured and preserved on the OCI instance:

* **Backup Directory:** `[REDACTED_BACKUP_PATH]`
* **Recorded Firewall State:** `[REDACTED_BACKUP_PATH]`
  - `FIREWALL_HTTP_PREEXISTING=false`
  - `FIREWALL_HTTPS_PREEXISTING=false`
* **Staged Files:** Preserved in `/home/opc/portfolio-deploy/`

---

## 11. Rollback Strategy & Emergency Instructions

If a rollback is ever requested in the future, the audited rollback script can be executed on the OCI instance:

### Interactive Rollback:
```bash
ssh -i <ssh-identity-key> -o IdentitiesOnly=yes opc@140.238.230.200
cd ~/portfolio-deploy/deployment
sudo ./rollback.sh
```

### Unattended / Emergency Rollback with Selective Firewall Reversion:
```bash
sudo ./rollback.sh --force --revert-firewall
```

### Rollback Guarantees:
1. Immediately deactivates and disables `caddy.service`.
2. Restores original configuration or safely cleans deployed files.
3. Automatically consults `firewall_state.env` and removes `http`/`https` **only because they were introduced by this deployment**.
4. Strictly leaves SSH (port 22), PCP, and Oracle Cloud Agent untouched.
5. Automatically archives the current webroot before cleanup so zero portfolio files are lost.

---

## 12. Conclusion & Verification Verdict

```
+----------------------------------------------------------------------------------+
|                                                                                  |
|      PRODUCTION DEPLOYMENT COMPLETED SUCCESSFULLY — VEYRION.IN IS LIVE           |
|                                                                                  |
+----------------------------------------------------------------------------------+
```

The personal engineering portfolio for **Supravat Dash** is live in production at:  
👉 **`https://veyrion.in/`**
