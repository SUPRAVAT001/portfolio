# Production Deployment Guide: `veyrion.in`
**Target Infrastructure:** Oracle Cloud Infrastructure (OCI) Always-Free Compute  
**Instance Name:** `instance-20261115-1749` (`VM.Standard.E2.1.Micro`)  
**Public IP:** `140.238.230.200` | **RAM:** 1.0 GB | **OS:** Oracle Linux 9.8  
**Architecture:** Standalone Caddy Web Server (Zero Package Manager / Zero Docker)  

---

## 1. Architectural Overview & Design Rationale

This deployment package provides an ultra-lightweight, zero-cost, memory-safe architecture designed specifically for the strict **1.0 GB RAM** constraint of the OCI Micro instance.

### Key Architectural Decisions:
1. **Zero Package Manager (`dnf`/`yum`):**  
   Oracle Linux 9's `dnf` consumes 400–600 MiB of RSS during repository metadata decompression and dependency calculation. On a 1 GB instance with ~291 MiB available RAM, running `dnf` triggers the Linux kernel OOM killer or system freezing. Caddy is deployed as a pre-compiled, standalone Linux AMD64 binary verified cryptographically with SHA-512.
2. **Zero Container Overhead (No Docker/Podman):**  
   Docker and containerd daemons consume 180–240 MiB idle RAM. Serving static files directly through Caddy uses only **18–25 MiB RSS**, leaving over 260 MiB of safety margin.
3. **Privilege Separation with Linux Capabilities:**  
   Caddy runs under a dedicated, unprivileged system account (`caddy:caddy`) with `nologin`. The systemd service grants `CAP_NET_BIND_SERVICE`, allowing binding to privileged ports 80 and 443 without root permissions.
4. **Autonomous HTTPS & OCSP:**  
   Caddy manages Let's Encrypt certificate issuance, OCSP stapling, and renewals 30 days before expiry automatically via ACME HTTP-01 challenges, with automatic ZeroSSL fallback.
5. **Cgroup Resource Guardrails:**  
   The systemd service enforces strict memory limits (`MemoryHigh=64M`, `MemoryMax=128M`) and task limits (`TasksMax=64`), guaranteeing the web server can never exhaust host memory or disrupt other processes (SSH, PCP, OCI agent).
6. **SELinux Enforcing Compliance:**  
   All files are labeled with standard SELinux security contexts (`httpd_sys_content_t` for the webroot, `var_log_t` for logs, `bin_t` for the binary).

---

## 2. Review of Proposed Architecture & Configuration Fixes

During the technical review of the initial deployment proposals, several critical configuration errors and operational risks were identified and resolved:

| Initial Proposal Item | Issue Identified | Resolution in Final Package |
| :--- | :--- | :--- |
| **Global `log` directive in `Caddyfile`** | Placed in global options `{ ... }`, which configures internal daemon runtime logs rather than HTTP access logs, and caused validation to fail if `/var/log/caddy` did not already exist. | Moved `log` into the site block `veyrion.in { log { ... } }`, using JSON formatting and specific access log routing. |
| **Log Rotation Subdirective** | Proposed `roll_keep_days 30`, which is an invalid token in Caddy v2 Caddyfile syntax and fails validation. | Corrected to official syntax `roll_keep_for 720h`. |
| **Content Security Policy (`script-src`)** | Proposed `script-src 'self'`, which blocks the essential inline `<script>` tags used in `<head>` on every page to prevent theme flicker (`localStorage.getItem('theme')`) and in redirect pages (`expertise`, `engineering`). | Updated to `script-src 'self' 'unsafe-inline'`, ensuring immediate theme bootstrapping functions without CSP violations. |
| **Binary Download Security** | Proposed downloading binary from API endpoint without cryptographic verification. | Replaced with official GitHub Releases download of `caddy_<version>_linux_amd64.tar.gz` and mandatory SHA-512 checksum validation against `caddy_<version>_checksums.txt`. |
| **Systemd Resource Controls** | Memory constraints were missing from proposed unit file. | Added `MemoryHigh=64M`, `MemoryMax=128M`, and `TasksMax=64` to `caddy.service`. |
| **Non-Destructive Safety** | Silent overwrite of existing configuration files. | Built automated timestamped backups into `/var/backups/caddy_predeploy_<timestamp>/` prior to any file writes. |

---

## 3. Package Structure

The deployment package is located in `/home/sdash/portfolio/deployment/`:

```
deployment/
├── Caddyfile              # Hardened production Caddy configuration
├── caddy.service          # Hardened, unprivileged systemd unit file
├── deploy.sh              # Automated deployment script with 10 safety phases
├── rollback.sh            # Safe rollback and recovery script
└── DEPLOYMENT_GUIDE.md    # This technical guide and manual steps
```

---

## 4. Pre-Deployment Manual Prerequisites (Required Before Deploy)

Before running the deployment script, the following three manual prerequisites must be completed:

### Prerequisite 1: Configure DNS at BigRock
Log in to the **BigRock Domain Control Panel** for `veyrion.in` and navigate to the **DNS Management Console**. Add the following two records:

1. **Root / Apex A Record:**
   - **Record Type:** `A`
   - **Host Name:** `@` (or leave blank depending on BigRock UI)
   - **Target / IP:** `140.238.230.200`
   - **TTL:** Select **4 Hours** (`14400` seconds) — this is the standard minimum TTL option in BigRock's management console.
2. **WWW Subdomain CNAME Record:**
   - **Record Type:** `CNAME`
   - **Host Name:** `www`
   - **Target / Destination:** `veyrion.in`
   - **TTL:** Select **4 Hours** (`14400` seconds).

> [!IMPORTANT]
> **DNS Propagation Window:** Because BigRock's minimum TTL is 4 hours (14,400s) and previous SOA negative caching may be cached by intermediate resolvers, global DNS propagation may take up to **2 to 4 hours**. The deployment preflight script (`deploy.sh`) strictly verifies that `veyrion.in` resolves to `140.238.230.200` before Caddy attempts to request an HTTPS certificate from Let's Encrypt, preventing ACME HTTP-01 challenge failures and Let's Encrypt rate-limiting lockouts.

*Verification:*  
From your local terminal, verify resolution before deploying:
```bash
python3 -c "import socket; print('veyrion.in ->', socket.gethostbyname('veyrion.in'))"
python3 -c "import socket; print('www.veyrion.in ->', socket.gethostbyname('www.veyrion.in'))"
```
*Both must resolve to `140.238.230.200` before running `./deploy.sh` without `--skip-dns-check`.*

---

### Prerequisite 2: Verify OCI Virtual Cloud Network (VCN) Ingress Rules
Ensure the OCI subnet firewall allows incoming web traffic to the instance:

1. Log in to the **Oracle Cloud Console**.
2. Navigate to: **Networking** > **Virtual Cloud Networks** > Select your VCN.
3. Under **Resources**, click **Security Lists** > Select the **Default Security List for your subnet**.
4. Review **Ingress Rules**. Ensure rules exist for ports **80** and **443**:
   - **Stateless:** `No`
   - **Source Type:** `CIDR`
   - **Source CIDR:** `0.0.0.0/0`
   - **IP Protocol:** `TCP`
   - **Destination Port Range:** `80, 443`
   - **Description:** `HTTP and HTTPS public ingress for veyrion.in`
5. If missing, click **Add Ingress Rules** and create them.

---

### Prerequisite 3: Update Canonical URLs in Local Portfolio
Before synchronizing files to the server, update the temporary sslip.io canonical URLs across the 10 HTML files and `robots.txt`/`sitemap.xml`:

- Find: `https://140-238-230-200.sslip.io/`
- Replace with: `https://veyrion.in/`

*(Per strict instructions, these files were not modified during the audit phase and should be updated as part of the authorized deployment step).*

---

## 5. Step-by-Step Deployment Execution

Once prerequisites are satisfied and approval is given:

### Step 5.1: Transfer Deployment Package to OCI Instance
From your local machine (`/home/sdash/portfolio`), upload the deployment package and site assets to the OCI instance:

```bash
# 1. Create staging directory on remote instance
ssh -i ~/.ssh/devops-jarvis-oci -o IdentitiesOnly=yes opc@140.238.230.200 "mkdir -p ~/portfolio-deploy"

# 2. Transfer deployment scripts and site files
rsync -avz -e "ssh -i ~/.ssh/devops-jarvis-oci -o IdentitiesOnly=yes" \
  /home/sdash/portfolio/deployment \
  /home/sdash/portfolio/site \
  opc@140.238.230.200:~/portfolio-deploy/
```

### Step 5.2: Execute Preflight Dry-Run on OCI Instance
SSH into the instance and run the preflight audit:

```bash
ssh -i ~/.ssh/devops-jarvis-oci -o IdentitiesOnly=yes opc@140.238.230.200
cd ~/portfolio-deploy/deployment
sudo ./deploy.sh --dry-run
```
*Expected output:* Confirms memory headroom (>150 MB), disk space (>1 GB), port availability (80/443 free), SSH health, and DNS resolution.

### Step 5.3: Execute Production Deployment
Execute the automated deployment:

```bash
sudo ./deploy.sh
```

If DNS has not propagated globally yet, you may test staging deployment using:
```bash
sudo ./deploy.sh --skip-dns-check
```

---

## 6. Post-Deployment Verification Checklist

Execute these verification commands from your local workstation:

### Test 1: Canonical WWW Redirect
Verify that requests to `www.veyrion.in` permanently redirect (301) to the canonical root `https://veyrion.in`:
```bash
curl -Iv https://www.veyrion.in/
```
*Expected:* `HTTP/2 301` with `Location: https://veyrion.in/`.

### Test 2: HTTP to HTTPS Automatic Upgrade
Verify that insecure requests automatically redirect to HTTPS:
```bash
curl -Iv http://veyrion.in/
```
*Expected:* `HTTP/1.1 308 Permanent Redirect` with `Location: https://veyrion.in/`.

### Test 3: HTTPS Handshake & Certificate Verification
Verify the primary production endpoint:
```bash
curl -Iv https://veyrion.in/
```
*Expected:* 
- `HTTP/2 200`
- TLS protocol: `TLSv1.3`
- Certificate issuer: `Let's Encrypt` (or `ZeroSSL`)
- Common Name: `veyrion.in`

### Test 4: Custom 404 Error Page
Verify that missing routes return a clean 404 status code while rendering `/404.html`:
```bash
curl -Iv https://veyrion.in/nonexistent-route
```
*Expected:* `HTTP/2 404` with custom 404 HTML body.

### Test 5: Security Headers Audit
Verify presence of defensive HTTP headers:
```bash
curl -sI https://veyrion.in/ | grep -iE 'strict-transport|x-content|x-frame|content-security|permissions|server'
```
*Expected Output:*
- `strict-transport-security: max-age=86400`
- `x-content-type-options: nosniff`
- `x-frame-options: DENY`
- `referrer-policy: strict-origin-when-cross-origin`
- `permissions-policy: camera=(), microphone=(), geolocation=(), payment=(), usb=()`
- `content-security-policy: default-src 'self'; script-src 'self' 'unsafe-inline'; ...`
- No `server: Caddy` banner (suppressed by `-Server`).

### Test 6: Verify Other Services Remain Unaffected
```bash
ssh -i ~/.ssh/devops-jarvis-oci -o IdentitiesOnly=yes opc@140.238.230.200 "
sudo systemctl status sshd pmcd oracle-cloud-agent --no-pager
sudo ss -tulpn | grep -E ':(22|80|443|44321)\b'
"
```
*Expected:* SSH (22), PCP (44321), and OCI Agent are active; ports 80/443 are handled by `caddy`.

---

## 7. Rollback & Emergency Recovery

If any unexpected issue occurs during or after deployment, execute the rollback script on the OCI instance:

### Standard Interactive Rollback:
```bash
cd ~/portfolio-deploy/deployment
sudo ./rollback.sh
```

### Unattended / Emergency Rollback (with firewall port closure):
```bash
sudo ./rollback.sh --force --revert-firewall
```

### What Rollback Does:
1. Immediately stops and disables `caddy.service`.
2. Restores configuration and webroot from `/var/backups/caddy_predeploy_<timestamp>/` (or cleans deployed files if fresh install).
3. Closes ports 80 and 443 in `firewalld` (if `--revert-firewall` is passed).
4. Verifies SSH port 22 and core services remain 100% active.

---

## 8. Ongoing Maintenance & Operations

### Viewing Live Logs:
- **HTTP Access Logs (JSON):**  
  `sudo tail -f /var/log/caddy/veyrion.in.access.log`
- **Systemd Process / ACME Logs:**  
  `sudo journalctl -u caddy -f`

### Zero-Downtime Site Updates:
To update static HTML, CSS, or images in the future, simply copy the updated files to `/var/www/veyrion.in/`:
```bash
rsync -avz --delete -e "ssh -i ~/.ssh/devops-jarvis-oci -o IdentitiesOnly=yes" \
  /home/sdash/portfolio/site/ \
  opc@140.238.230.200:/var/www/veyrion.in/
```
*No service restart or reload is required; Caddy serves static files directly from the filesystem.*

### Reloading Caddy Configuration:
If `Caddyfile` is modified:
```bash
sudo /usr/local/bin/caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```
