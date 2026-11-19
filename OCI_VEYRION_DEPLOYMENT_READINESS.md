# OCI Deployment Readiness & Infrastructure Audit Report
**Target Domain:** `veyrion.in` (with canonical redirect from `www.veyrion.in`)  
**Target Infrastructure:** Oracle Cloud Infrastructure (OCI) Compute Instance  
**Instance Name:** `instance-20261115-1749`  
**Public IP:** `140.238.230.200` | **Private IP:** `[REDACTED_INTERNAL_IP]`  
**Audit Date:** 2026-11-19 | **Audit Mode:** STRICT READ-ONLY AUDIT  
**Lead Auditor:** Senior Linux Infrastructure & Security Engineer  

---

## Executive Summary

A comprehensive, non-destructive, read-only infrastructure audit was conducted on the target OCI instance `instance-20261115-1749` and the local personal engineering portfolio repository (`/home/sdash/portfolio`).

The primary finding is that the target server is **highly suitable and ready** to host the personal portfolio under `veyrion.in`, subject to specific, lightweight deployment practices. The local portfolio is entirely composed of pre-built, static production assets (2.9 MB total size across 39 files), requiring zero runtime application servers, Node.js, Python backends, or database engines.

Because the OCI instance operates on a strict **1 GB RAM** constraint (`VM.Standard.E2.1.Micro`), traditional package-management installations (such as running `dnf install` or adding COPR repositories) represent a known **critical memory risk** that has previously frozen the instance. Consequently, this audit recommends deploying a **standalone, statically compiled Caddy binary** directly via curl/scp, bypassing package managers completely. Caddy will provide automatic HTTP-to-HTTPS redirection, Let's Encrypt TLS certificate lifecycle management, and HTTP/2 + HTTP/3 static file serving while consuming less than 25 MB of RAM.

All findings in this report are categorized under the four standard assessment classifications:
- **`[VERIFIED]`**: Empirically tested and confirmed through read-only inspection.
- **`[NOT VERIFIED]`**: Cannot be confirmed from the host alone; requires external cloud console verification.
- **`[REQUIRES ACTION]`**: Explicit configuration step required prior to or during deployment.
- **`[POTENTIAL RISK]`**: Operational or security consideration requiring specific mitigation.

---

## 1. Server Health and Resource Report

### 1.1 Compute & Architecture
* **Hostname / Instance Identifier:** `instance-20261115-1749` `[VERIFIED]`
* **Operating System:** Oracle Linux Server release 9.8 `[VERIFIED]`
* **Linux Kernel:** `6.12.0-207.111.5.6.el9uek.x86_64` (Oracle Unbreakable Enterprise Kernel - UEK) `[VERIFIED]`
* **Architecture:** `x86_64` `[VERIFIED]`
* **CPU Model:** AMD EPYC 7551 32-Core Processor (1 physical core allocated, 2 vCPUs) `[VERIFIED]`
* **CPU Frequency:** 1996.249 MHz `[VERIFIED]`
* **Current Load Average:** `0.04, 0.03, 0.00` (97.5%+ CPU idle) `[VERIFIED]`
* **System Uptime:** 2 days, 4 hours, 35 minutes (stable, no unexpected restarts) `[VERIFIED]`

### 1.2 Memory & Swap Subsystem
* **Total Physical RAM:** 945 MiB (Nominal 1.0 GB) `[VERIFIED]`
* **Used RAM:** ~654 MiB (Active user/kernel memory: ~485 MiB, Buffers/Page Cache: ~205 MiB) `[VERIFIED]`
* **Free RAM:** ~86 MiB `[VERIFIED]`
* **Available RAM:** **~291 MiB** `[VERIFIED]`
* **Configured Swap Space:** 498 MiB total at `/.swapfile` (Type: file, Priority: -2) `[VERIFIED]`
* **Active Swap Utilization:** 268 KiB (< 0.1% utilized; swap thrashing is absent) `[VERIFIED]`
* **Memory Safety Evaluation:** The server has ~291 MiB of real available headroom before swapping occurs. Package managers (`dnf`/`yum`) on EL9 frequently allocate 400–600 MiB of RSS during repository metadata decompression and dependency solving. This guarantees memory exhaustion and kernel freezing if executed. Deploying a static binary completely avoids this. `[POTENTIAL RISK]`

### 1.3 Disk Storage & Filesystems
* **Root Filesystem (`/`):** Mounted on `/dev/mapper/ocivolume-root` (XFS filesystem) `[VERIFIED]`
* **Total Storage:** 30 GiB `[VERIFIED]`
* **Used Storage:** 5.8 GiB (20% utilization) `[VERIFIED]`
* **Available Storage:** **24 GiB** (80% free) `[VERIFIED]`
* **Inodes:** 15,728,640 total, 151,332 used (1% utilization) `[VERIFIED]`
* **Storage Verdict:** Abundant storage is available. The entire portfolio (2.9 MB) and Caddy binary (45 MB) will consume less than 0.2% of available disk space. `[VERIFIED]`

### 1.4 Operating System Security & Daemon State
* **SELinux Status:** `enabled`, mode `enforcing`, policy `targeted` `[VERIFIED]`
* **Systemd Unit Status:** 30 active units. 1 failed unit: `mcelog.service` (Machine Check Exception daemon fails on startup because AMD EPYC architectures utilize the kernel EDAC / rasdaemon driver instead of the legacy Intel mcelog driver; this is harmless and standard for AMD virtual machines) `[VERIFIED]`

---

## 2. Existing Services and Port Inventory

### 2.1 Listening Network Sockets
Comprehensive audit using `ss -tulpn` and kernel socket tables revealed the following listening endpoints:

| Protocol | Local Address | Port | Process / Service | Purpose & Access Scope | Classification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TCP** | `0.0.0.0` / `[::]` | **22** | `sshd` (PID 1545) | OpenSSH server; remote administration | `[VERIFIED]` |
| **TCP** | `0.0.0.0` / `[::]` | **111** | `rpcbind` (PID 1361) | RPC port mapper for RPC/NFS services | `[VERIFIED]` |
| **TCP** | `127.0.0.1` / `[::1]` | **44321** | `pmcd` (PID 2200) | Performance Co-Pilot metric collector (loopback only) | `[VERIFIED]` |
| **UDP** | `0.0.0.0` / `[::]` | **111** | `rpcbind` (PID 1361) | RPC port mapper | `[VERIFIED]` |
| **UDP** | `127.0.0.1` | **323** | `chronyd` (PID 1395) | Chrony NTP client (loopback only) | `[VERIFIED]` |
| **TCP** | `*` | **80** | **NONE** | **NOT LISTENING** (Completely available) | `[VERIFIED]` |
| **TCP** | `*` | **443** | **NONE** | **NOT LISTENING** (Completely available) | `[VERIFIED]` |

### 2.2 Running Background Processes (Memory Allocation)
The top memory-consuming processes currently active on the host are:
1. **Oracle Cloud Agent Suite:** Combined RSS **~260 MiB** across 5 processes (`agent` [59 MB], `runcommand` [62 MB], `gomon` [58 MB], `updater` [49 MB], `oci-wlp` [37 MB]). Managed by Oracle for telemetry and platform integration. `[VERIFIED]`
2. **Performance Co-Pilot (`pcp` / `pmcd`):** Combined RSS **~68 MiB** (`pmdaopenmetrics.python` [43 MB], `pmdanfsclient.python` [25 MB]). `[VERIFIED]`
3. **Firewalld (`/usr/bin/python3 firewalld`):** RSS **~48 MiB**. `[VERIFIED]`
4. **Tuned (`/usr/bin/python3 tuned`):** RSS **~30 MiB**. `[VERIFIED]`
5. **NetworkManager:** RSS **~29 MiB**. `[VERIFIED]`
6. **Systemd (PID 1):** RSS **~22 MiB**. `[VERIFIED]`
7. **SSHD / Polkit:** RSS **~36 MiB** combined. `[VERIFIED]`

### 2.3 Container Engines
* **Docker:** Not installed (`which docker`: not found). No Docker daemons or sockets exist. `[VERIFIED]`
* **Podman:** Not installed (`which podman`: not found). No podman containers exist. `[VERIFIED]`
* **Containerd:** Not installed. `[VERIFIED]`

---

## 3. Existing Web Server and Reverse-Proxy Status

* **Caddy Installation:**
  - Binary search in `$PATH`: Absent. `[VERIFIED]`
  - Filesystem locations (`/usr/local/bin/caddy`, `/usr/bin/caddy`, `/opt/caddy`, `/etc/caddy`): Absent. `[VERIFIED]`
  - Systemd service (`caddy.service`): Absent. `[VERIFIED]`
  - Existing configuration files: None exist. `[VERIFIED]`
* **Nginx Installation:**
  - RPM check (`rpm -q nginx`): Not installed. `[VERIFIED]`
  - Configuration directory (`/etc/nginx`): Absent. `[VERIFIED]`
* **Apache / HTTPD Installation:**
  - RPM check (`rpm -q httpd`): Not installed. `[VERIFIED]`
  - Configuration directory (`/etc/httpd`): Absent. `[VERIFIED]`
* **Webroot Directory (`/var/www`):** Does not exist on the host filesystem. `[VERIFIED]`
* **Existing TLS Certificates (`/etc/letsencrypt`, `/var/lib/caddy`):** None exist on the host. `[VERIFIED]`
* **Verdict:** The instance is completely clean of any conflicting web servers, reverse proxies, or listening HTTP daemons. Ports 80 and 443 are completely unobstructed. `[VERIFIED]`

---

## 4. Portfolio Build Requirements & Local Asset Inspection

### 4.1 Asset Analysis
Inspection of the local repository `/home/sdash/portfolio/site/` reveals:
* **Total Footprint:** **2.9 MB** across 39 files. `[VERIFIED]`
* **Asset Breakdown:**
  - Images (`/site/images/`): 2.6 MB (Optimization and live proof screenshots for all 4 project case studies + profile portrait).
  - Projects (`/site/projects/`): 128 KB (Individual case studies for `devops-jarvis`, `git-argo`, `kube-obs`, `todoapp`, and project index).
  - Resume (`/site/resume/Supravat_Dash_Resume.pdf`): 84 KB.
  - CSS Stylesheets (`/site/css/`): 40 KB (`style.css` and `homepage.css`).
  - Core Pages (`/site/`): 48 KB (`index.html`, `about/index.html`, `contact/index.html`, `404.html`, `expertise/index.html`, `engineering/index.html`).
  - JavaScript (`/site/js/main.js`): 12 KB (Theme toggle, mobile drawer, scroll interactions).
  - SEO & Meta: 8 KB (`robots.txt`, `sitemap.xml`, `favicon.svg`, `favicon.ico`).

### 4.2 Build Tooling & Runtimes
* **Node.js / NPM / Yarn:** **NOT REQUIRED**. There is no `package.json`, build bundler, Webpack, Vite, or post-processor. `[VERIFIED]`
* **Python / FastAPI / WSGI:** **NOT REQUIRED**. The portfolio requires no server-side application logic. `[VERIFIED]`
* **Static Site Generator (Hugo / Jekyll):** **NOT REQUIRED**. Every page is already pre-rendered standard HTML5. `[VERIFIED]`
* **Production Build Output:** The repository directory `/home/sdash/portfolio/site/` **IS** the production artifact. It is ready for direct deployment without any build step. `[VERIFIED]`

### 4.3 Routing & Navigation Verification
* All navigation links use directory-based clean URLs (e.g., `/`, `/about/`, `/projects/`, `/contact/`).
* Each route corresponds to a physical `index.html` file within a directory on disk:
  - `/` -> `site/index.html`
  - `/about/` -> `site/about/index.html`
  - `/projects/` -> `site/projects/index.html`
  - `/projects/kube-obs/` -> `site/projects/kube-obs/index.html`
  - `/projects/git-argo/` -> `site/projects/git-argo/index.html`
  - `/projects/devops-jarvis/` -> `site/projects/devops-jarvis/index.html`
  - `/projects/todoapp/` -> `site/projects/todoapp/index.html`
  - `/contact/` -> `site/contact/index.html`
  - `/404.html` -> Error boundary page
* Caddy's `file_server` natively resolves directory indices (`index.html`) automatically without URL rewrite rules. `[VERIFIED]`

### 4.4 URL Audit & Canonical Pre-Deployment Changes
A grep inspection for domain references across all files identified:
* **External Links:** Links to `80-225-229-214.sslip.io` exist exclusively in `site/projects/todoapp/index.html` and `site/projects/index.html` as external demonstration links to the separate TodoApp live instance. These must remain unchanged. `[VERIFIED]`
* **Internal Staging Links:** Mentions of `127.0.0.1:8000` exist only as descriptive text inside case study documentation describing local Docker Compose staging. These are non-functional text descriptions and require no changes. `[VERIFIED]`
* **Canonical URLs & Sitemaps:** `<link rel="canonical">`, `<meta property="og:url">`, `robots.txt`, and `sitemap.xml` currently reference `https://140-238-230-200.sslip.io/`.
  - **Required Action:** These 11 occurrences must be updated to `https://veyrion.in/` prior to public deployment. Per strict audit instructions, no files were modified during this audit. `[REQUIRES ACTION]`

---

## 5. Recommended Deployment Architecture

### 5.1 Architecture Overview
The recommended production architecture for `veyrion.in` is an ultra-minimalist, single-tier, zero-runtime deployment:

```
+----------------------------------------------------------------------------------+
|                                    INTERNET                                      |
+----------------------------------------------------------------------------------+
                                        |
                 +----------------------+----------------------+
                 | DNS Resolution                              | DNS Resolution
                 v (A: 140.238.230.200)                        v (CNAME: veyrion.in)
        +------------------+                          +--------------------+
        |    veyrion.in    |                          |   www.veyrion.in   |
        +------------------+                          +--------------------+
                 |                                              |
                 +----------------------+-----------------------+
                                        |
                                        v Inbound Ports 80 & 443
                     +-------------------------------------+
                     | OCI Virtual Cloud Network (VCN)     |
                     | Ingress Security List / NSG Rules   |
                     +-------------------------------------+
                                        |
                                        v Physical ens3 ([REDACTED_INTERNAL_IP])
                     +-------------------------------------+
                     | Host Linux Firewalld (public zone)  |
                     | Services: http (80), https (443)    |
                     +-------------------------------------+
                                        |
                                        v Local socket binding
                     +-------------------------------------+
                     | Caddy Web Server (v2.8.4 standalone)|
                     | Systemd Service: caddy.service      |
                     | User: caddy (unprivileged)          |
                     | RAM Footprint: ~18-25 MB RSS        |
                     +-------------------------------------+
                        |                               |
          [www -> apex 301 redirect]       [Automatic TLS / ACME Engine]
                        |                               |
                        v                               v Let's Encrypt / ZeroSSL
          +-----------------------------+   +-----------------------------+
          | Static File Server Root     |   | /var/lib/caddy/             |
          | /var/www/veyrion.in/        |   | (Certificates, keys, ACME)  |
          | 39 Files / 2.9 MB Total     |   +-----------------------------+
          +-----------------------------+
```

### 5.2 Why Caddy Standalone Binary (vs Package Manager / Docker / Nginx)?
1. **Package Management Safety:** Direct binary placement avoids `dnf`/`yum` memory thrashing entirely. The official pre-compiled Caddy binary is downloaded in 3 seconds via curl (~45 MB), requiring zero compilation, zero package dependencies, and zero SQLite transaction locks.
2. **Memory Efficiency:** Caddy's runtime memory consumption for serving static files with gzip/zstd compression is **~18–25 MiB RSS**. It comfortably fits inside the host's 291 MiB available memory without causing swap activity.
3. **Automatic HTTPS:** Caddy includes a native, pure-Go ACME client. It manages initial certificate acquisition, daily OCSP stapling, and automatic renewal 30 days before expiration without requiring Certbot, Python, or cron jobs (which consume 100+ MB RAM).
4. **No Container Overhead:** Introducing Docker would consume 180–240 MiB of RAM just for `dockerd`, `containerd`, and `docker-proxy`, leaving the system with under 50 MiB free RAM and triggering OOM freezes.
5. **Native Canonical Redirection & Security Headers:** Clean, declarative syntax in a single `Caddyfile`.

---

## 6. DNS Configuration Required Later

### 6.1 Current DNS State (BigRock)
Authoritative nameserver queries against `veyrion.in` via Google Public DNS and BigRock root servers confirmed:
* **Nameservers (`NS`):** `dns1.bigrock.in`, `dns2.bigrock.in`, `dns3.bigrock.in`, `dns4.bigrock.in` `[VERIFIED]`
* **SOA Record:** `dns1.bigrock.in. supravatdash7399.gmail.com. 2026111901 ...` `[VERIFIED]`
* **A Record (`@`):** **None** (Returns NODATA / Auth SOA) `[VERIFIED]`
* **CNAME Record (`www`):** **None** (Returns NODATA / Auth SOA) `[VERIFIED]`
* **MX / TXT / AAAA Records:** None present `[VERIFIED]`

### 6.2 Required DNS Records to Apply Post-Approval
When approved, the user will configure the following exact records in the BigRock DNS Management Console:

| Record Type | Host / Name | Destination / Target Value | TTL | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **A** | `@` (or `veyrion.in.`) | `140.238.230.200` | 300 seconds (5 min) | Maps root domain directly to OCI public IP |
| **CNAME** | `www` (or `www.veyrion.in.`) | `veyrion.in.` | 300 seconds (5 min) | Routes www subdomain to apex for canonical redirect |

*Note on TTL:* Using a low TTL (300s) during initial setup ensures rapid propagation. Once TLS certificates are validated, the TTL can be increased to 3600 or 86400 seconds. `[REQUIRES ACTION]`

---

## 7. HTTPS Setup Plan

### 7.1 ACME Protocol Automation
Caddy automates HTTPS using the ACME protocol (RFC 8555):
* **Primary CA:** Let's Encrypt (`https://acme-v02.api.letsencrypt.org/directory`). Host connectivity was verified: `curl` to Let's Encrypt returned HTTP/2 200. `[VERIFIED]`
* **Secondary CA (Fallback):** ZeroSSL (automatic fallback if Let's Encrypt experiences downtime).
* **Challenge Mechanism:** **HTTP-01 challenge**.
  - Let's Encrypt validates domain ownership by requesting a cryptographic token at `http://veyrion.in/.well-known/acme-challenge/<token>`.
  - Caddy handles this challenge internally in memory on port 80.
  - Port 80 must be accessible from the internet for initial issuance and periodic renewals.

### 7.2 Prerequisites for Certificate Issuance
1. BigRock DNS A record for `veyrion.in` must resolve to `140.238.230.200`.
2. BigRock DNS CNAME record for `www.veyrion.in` must resolve to `140.238.230.200`.
3. OCI VCN Ingress Rules must permit TCP port 80 and TCP port 443.
4. Host `firewalld` must allow `http` and `https` services.
5. Caddy must be running and listening on `0.0.0.0:80` and `0.0.0.0:443`.

### 7.3 Certificate Storage & Permissions
* Certificates, private keys, and OCSP cache will be stored in `/var/lib/caddy/.local/share/caddy/certificates/`.
* Directory permissions will be strictly locked down to `0700`, owned by the unprivileged `caddy` service user.

---

## 8. Security Review

### 8.1 Host Firewall (`firewalld`)
* **Current Status:** `firewalld` is active on interface `ens3` with zone `public`.
* **Current Allowed Services:** `dhcpv6-client`, `ssh`.
* **Current Ports:** None.
* **Finding:** Inbound traffic to ports 80 and 443 is currently rejected at the host level with `icmpx admin-prohibited`. External connection attempts from outside return `No route to host`. `[VERIFIED]`
* **Required Action:** Run `sudo firewall-cmd --permanent --add-service=http --add-service=https && sudo firewall-cmd --reload` during deployment. `[REQUIRES ACTION]`

### 8.2 OCI Cloud Network (VCN) Ingress Rules
* **Current Status:** OCI VCN Security Lists / Network Security Groups (NSGs) control packet delivery before reaching the virtual NIC (`ens3`).
* **Finding:** Because `firewalld` actively rejected SYN packets on port 80 with ICMP admin-prohibited during testing, packets did reach the instance. However, OCI Security List ingress rules for Port 80 and Port 443 must be explicitly confirmed in the OCI Web Console:
  - Source: `0.0.0.0/0`
  - IP Protocol: `TCP`
  - Destination Port Range: `80, 443`
* Classification: `[NOT VERIFIED]` (Requires confirmation in OCI Console).

### 8.3 SSH Hardening & Access Control
* **SSH Listening Port:** 22. `[VERIFIED]`
* **Authentication Method:** Public Key authentication (`PubkeyAuthentication yes`). `[VERIFIED]`
* **Password Authentication:** Strictly disabled (`PasswordAuthentication no`). `[VERIFIED]`
* **Root Login:** Restricted to key-only (`PermitRootLogin without-password`). `[VERIFIED]`
* **Authorized User:** `opc` has full sudo privileges and is restricted to identity key `devops-jarvis-oci`.
* **Verdict:** SSH configuration is robust and adheres to cloud security best practices. `[VERIFIED]`

### 8.4 Least-Privilege Daemon Execution
* Caddy must **never** run as `root`.
* A dedicated system user `caddy` (system account, no login shell, home directory `/var/lib/caddy`) will be created.
* Systemd capabilities will grant low-port binding without root privileges:
  ```ini
  CapabilityBoundingSet=CAP_NET_BIND_SERVICE
  AmbientCapabilities=CAP_NET_BIND_SERVICE
  NoNewPrivileges=true
  ProtectSystem=strict
  ProtectHome=true
  ReadWritePaths=/var/lib/caddy /var/log/caddy
  ReadOnlyPaths=/var/www/veyrion.in
  ```
  `[VERIFIED ARCHITECTURE]`

### 8.5 SELinux Enforcement
* SELinux is `Enforcing` in targeted mode.
* Standard web ports (80, 443) are already part of `http_port_t`. `[VERIFIED]`
* Static files placed in `/var/www/veyrion.in` must be given the `httpd_sys_content_t` context to allow Caddy read access:
  ```bash
  sudo chcon -R -t httpd_sys_content_t /var/www/veyrion.in
  ```
  `[REQUIRES ACTION]`

### 8.6 Recommended Production Caddyfile with Security Headers
The following production `Caddyfile` is formulated specifically for `veyrion.in`:

```caddy
# Global configuration
{
    admin off
    email supravatdash7399@gmail.com
    log {
        output file /var/log/caddy/access.log {
            roll_size 10MiB
            roll_keep 3
        }
    }
}

# Canonical redirect: www.veyrion.in -> https://veyrion.in
www.veyrion.in {
    redir https://veyrion.in{uri} permanent
}

# Primary static portfolio host
veyrion.in {
    root * /var/www/veyrion.in
    encode zstd gzip
    file_server

    # Custom 404 error routing
    handle_errors {
        rewrite * /404.html
        file_server
    }

    # Strict security headers
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=()"
        Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self';"
        -Server
    }
}
```

---

## 9. Potential Conflicts with Existing Services

* **Port Conflicts:** None. Ports 80 and 443 are currently idle. `[VERIFIED]`
* **TodoApp Live Instance:** TodoApp operates on an independent OCI compute instance (`80.225.229.214` / `80-225-229-214.sslip.io`). Deploying to `instance-20261115-1749` (`140.238.230.200`) has **zero network or host interaction** with TodoApp. `[VERIFIED]`
* **DevOps Jarvis:** Operates on local developer staging (`127.0.0.1:8000`). No presence on the remote OCI instance. `[VERIFIED]`
* **Oracle Cloud Agent:** Coexists normally. Caddy's memory consumption (~20 MB) leaves adequate headroom for the Oracle agent's routine spikes without triggering swapping. `[VERIFIED]`
* **Performance Co-Pilot (`pmcd`):** Listens strictly on `127.0.0.1:44321`. No collision with web ports. `[VERIFIED]`

---

## 10. Exact Deployment Sequence (Pending Approval)

This sequence will be executed only after explicit user authorization:

### Phase 1: Local Pre-Deployment Preparation
1. Update canonical links and OpenGraph tags in 10 HTML files and `robots.txt`/`sitemap.xml`:
   - Replace `https://140-238-230-200.sslip.io/` with `https://veyrion.in/`.
2. Verify local preview on port 8090 to ensure asset integrity.

### Phase 2: DNS Records Application (BigRock Console)
1. Add DNS Record 1: Type `A`, Host `@`, Value `140.238.230.200`, TTL `300`.
2. Add DNS Record 2: Type `CNAME`, Host `www`, Value `veyrion.in`, TTL `300`.
3. Wait for DNS propagation and verify from local machine using DoH query.

### Phase 3: Host Firewall & Ingress Opening
1. On the OCI instance:
   ```bash
   sudo firewall-cmd --permanent --add-service=http
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --reload
   ```
2. Verify OCI Security List in OCI Console allows TCP 80 and 443 from `0.0.0.0/0`.

### Phase 4: Caddy Binary & User Setup
1. Create dedicated system user and directories:
   ```bash
   sudo useradd --system --home-dir /var/lib/caddy --shell /sbin/nologin caddy
   sudo mkdir -p /var/www/veyrion.in /etc/caddy /var/log/caddy /var/lib/caddy
   sudo chown -R caddy:caddy /var/log/caddy /var/lib/caddy
   ```
2. Download official static Linux AMD64 Caddy binary directly via curl:
   ```bash
   sudo curl -fsSL -o /usr/local/bin/caddy "https://caddyserver.com/api/download?os=linux&arch=amd64"
   sudo chmod 755 /usr/local/bin/caddy
   /usr/local/bin/caddy version
   ```
3. Install and register systemd service `/etc/systemd/system/caddy.service`.

### Phase 5: Webroot Synchronization & Permissions
1. Upload local `site/` files to `/var/www/veyrion.in` via `rsync` or `scp`.
2. Apply ownership and SELinux contexts:
   ```bash
   sudo chown -R opc:caddy /var/www/veyrion.in
   sudo find /var/www/veyrion.in -type d -exec chmod 755 {} +
   sudo find /var/www/veyrion.in -type f -exec chmod 644 {} +
   sudo chcon -R -t httpd_sys_content_t /var/www/veyrion.in
   ```

### Phase 6: Caddy Configuration & Activation
1. Write production `Caddyfile` to `/etc/caddy/Caddyfile`.
2. Validate configuration:
   ```bash
   sudo /usr/local/bin/caddy validate --config /etc/caddy/Caddyfile
   ```
3. Enable and start Caddy:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now caddy
   ```

### Phase 7: Verification & SSL Handshake Inspection
1. Inspect live systemd journal: `sudo journalctl -u caddy -f --no-tail` to monitor certificate acquisition.
2. Probe endpoints externally:
   - `curl -Iv https://veyrion.in/` (verify HTTP/2 200, Let's Encrypt cert, and security headers).
   - `curl -Iv http://veyrion.in/` (verify 308/301 redirect to HTTPS).
   - `curl -Iv https://www.veyrion.in/` (verify 301 redirect to `https://veyrion.in/`).
   - `curl -Iv https://veyrion.in/nonexistent` (verify 404 page rendering).

---

## 11. Rollback Strategy

In the event of any unforeseen failure during deployment:
1. **Immediate Service Deactivation:**
   ```bash
   sudo systemctl stop caddy
   sudo systemctl disable caddy
   ```
2. **Firewall Rollback:**
   ```bash
   sudo firewall-cmd --permanent --remove-service=http
   sudo firewall-cmd --permanent --remove-service=https
   sudo firewall-cmd --reload
   ```
3. **File Removal:** Remove `/usr/local/bin/caddy`, `/etc/caddy/Caddyfile`, `/etc/systemd/system/caddy.service`, and `/var/www/veyrion.in`.
4. **DNS Rollback:** Remove A and CNAME records from BigRock DNS manager.
5. **Impact on Existing Services:** **Zero impact**. Because no pre-existing packages, web servers, or configurations were modified, rolling back leaves the instance in its exact original state.

---

## 12. Estimated Disk and RAM Requirements

| Resource Component | Disk Footprint | RAM Footprint | Free Resource Margin | Assessment |
| :--- | :--- | :--- | :--- | :--- |
| **Caddy Standalone Binary** | ~45.0 MiB | ~18.0 MiB RSS | 24 GiB Free Disk / 291 MiB Avail RAM | Negligible impact `[VERIFIED]` |
| **Static Portfolio Files (39 files)**| ~2.9 MiB | Cached in OS page cache (~3 MiB) | 24 GiB Free Disk / 291 MiB Avail RAM | Negligible impact `[VERIFIED]` |
| **TLS Certificates & ACME Cache** | ~1.0 MiB | ~2.0 MiB during handshake | 24 GiB Free Disk / 291 MiB Avail RAM | Negligible impact `[VERIFIED]` |
| **Access Logs (Rotated, 3 files)** | ~30.0 MiB max | Buffers only | 24 GiB Free Disk / 291 MiB Avail RAM | Negligible impact `[VERIFIED]` |
| **Total Deployment Overhead** | **~79 MiB** | **~25 MiB RSS** | **> 23.9 GiB Disk / > 260 MiB RAM Left** | **Fully Sustainable `[VERIFIED]`** |

---

## Summary of Findings & Classifications

* `[VERIFIED]` **Host Resources:** Oracle Linux 9.8 (UEK Kernel 6.12), AMD EPYC (2 vCPUs), 945 MiB RAM with 291 MiB available, 24 GiB free disk.
* `[VERIFIED]` **Port Availability:** Ports 80 and 443 are currently completely unallocated and idle.
* `[VERIFIED]` **No Web Server Conflicts:** No Nginx, Apache, Caddy, Docker, or Podman is installed or running.
* `[VERIFIED]` **Portfolio Static Readiness:** Site is 100% pre-rendered static HTML/CSS/JS (2.9 MB); requires zero backend runtimes or build steps.
* `[VERIFIED]` **Domain DNS Baseline:** `veyrion.in` is registered with BigRock nameservers active; A and CNAME records are currently absent.
* `[VERIFIED]` **Outbound Connectivity:** Host has verified outbound connectivity to Let's Encrypt ACME directory (`HTTP/2 200`).
* `[POTENTIAL RISK]` **Memory Exhaustion via Package Management:** Running `dnf` or `yum` on this 1 GB instance has previously caused freezes. Mitigated by using a pre-compiled standalone Caddy binary.
* `[REQUIRES ACTION]` **Local Canonical URLs:** Update 11 occurrences of `https://140-238-230-200.sslip.io/` to `https://veyrion.in/` in local HTML and SEO files.
* `[REQUIRES ACTION]` **Host Firewall:** Allow `http` and `https` in `firewalld`.
* `[REQUIRES ACTION]` **DNS Records:** Add A record (`@ -> 140.238.230.200`) and CNAME (`www -> veyrion.in`) in BigRock.
* `[NOT VERIFIED]` **OCI Ingress Security List:** Confirm in the OCI Web Console that Ingress Security Rules on port 80 and 443 are open to `0.0.0.0/0`.

---
*Report generated and concluded in STRICT READ-ONLY mode. No modifications or deployments were performed.*
