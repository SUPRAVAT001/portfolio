# Production Deployment & Migration Report: TodoApp (todo.veyrion.in)

**Deployment Date**: November 19, 2026  
**Status**: **DEPLOYED & FULLY VERIFIED IN PRODUCTION**  
**Production Canonical URL**: [https://todo.veyrion.in/](https://todo.veyrion.in/)  
**Legacy Host Redirect**: [https://80-225-229-214.sslip.io/](https://80-225-229-214.sslip.io/) &rarr; `HTTP 301 https://todo.veyrion.in/`  
**Target Server**: Oracle Cloud Infrastructure (OCI) — `80.225.229.214`  
**Portfolio Host**: `140.238.230.200` (`https://veyrion.in/`) — **COMPLETELY UNTOUCHED & VERIFIED OPERATIONAL**

---

## 1. Executive Summary

The production security hardening, hostname migration, and reverse-proxy deployment for **TodoApp** have been successfully executed on the target OCI production host (`80.225.229.214`).

The application is now accessible via automated Let's Encrypt TLSv1.3 at [https://todo.veyrion.in/](https://todo.veyrion.in/). The legacy host (`80-225-229-214.sslip.io`) and plaintext port 80 traffic are permanently redirected to the canonical domain. The application process has been migrated from the interactive `opc` login account into a sandboxed, unprivileged system user (`todoapp:todoapp`, `/sbin/nologin`) enforced by systemd hardening directives and SELinux.

All 28 live end-to-end production verification checks passed without error, confirming strict CSRF validation, proactive in-memory rate limiting, suppression of server headers, disabling of interactive OpenAPI documentation in production, complete user CRUD lifecycle execution, multi-tenant isolation, and complete preservation of pre-existing database records.

---

## 2. Infrastructure Identity & Target Architecture

| Component | Target Host Specification | Details / Status |
| :--- | :--- | :--- |
| **Instance Name** | `instance-20261115-1737` | Dedicated TodoApp OCI instance |
| **Public IPv4** | `80.225.229.214` | Oracle Cloud Infrastructure (ap-singapore-1) |
| **Operating System** | Oracle Linux Server 9.8 | Kernel `6.12.0-100.1.3.el9uek.x86_64` (UEK) |
| **SELinux Mode** | **Enforcing** | Hardened security policy active |
| **Compute Shape** | VM.Standard.E2.1.Micro | AMD EPYC 7551, 1 vCPU, 1.0 GB RAM |
| **Reverse Proxy** | Caddy v2.9.1 | Automatic Let's Encrypt HTTPS, H3/H2/H1.1 |
| **ASGI Server** | Uvicorn 0.34.0 | Running on `127.0.0.1:8000` (loopback only) |
| **Application User** | `todoapp:todoapp` | UID 986, GID 986, Shell `/sbin/nologin` |
| **App Directory** | `/home/todoapp/apps/todoapp` | Isolated unprivileged application root |
| **Database Engine** | PostgreSQL (Neon Cloud) | Preserved existing connection; 0 schema changes |
| **Portfolio Host** | `140.238.230.200` (`veyrion.in`) | **COMPLETELY UNTOUCHED** (Verified 200 OK) |

---

## 3. Stage-by-Stage Deployment Record

### Stage 1: Pre-Deployment Verification & DNS Resolution
1. **Local Remediation Tests**: All 30 security tests (`test_security_remediation.py`) verified passing locally prior to remote deployment.
2. **DNS Resolution**: Verified via Google (`8.8.8.8`) and Cloudflare (`1.1.1.1`) DNS-over-HTTPS APIs:
   - `todo.veyrion.in` &rarr; `A` record pointing to `80.225.229.214` (TTL: 14400s).
3. **Target System Resources**:
   - Host confirmed: 395 MiB available RAM, 23 GiB free root filesystem space.
   - Verified target server identity (`instance-20261115-1737`).
4. **Database State Preflight**:
   - Verified read-only connectivity to PostgreSQL.
   - Pre-existing records confirmed: User ID 8 (`supdhhh@gmail.com`) and Todo ID 4 (`finish task`).

### Stage 2: Comprehensive Server Backups
Before modifying any configuration or files on `80.225.229.214`, an immutable backup snapshot was recorded at:
`[REDACTED_BACKUP_PATH]`

Archive inventory:
- `app_code.tar.gz` (308,834 bytes): Full pre-deployment `/home/opc/apps/todoapp/` codebase snapshot.
- `Caddyfile.bak` (203 bytes): Original Caddyfile reverse-proxy config.
- `todoapp.service.bak` (447 bytes): Original systemd service unit.
- `.env.bak` (326 bytes, permissions `0600`): Environment configuration with original database credentials.
- `firewall_state.txt` (255 bytes): `firewall-cmd --list-all` configuration capture.
- `services_state.txt` (7,242 bytes): Running systemd services and socket status snapshot.

### Stage 3: Dedicated Service Account & Isolation
1. Created dedicated system service user and group:
   ```bash
   sudo useradd -r -s /sbin/nologin -d /home/todoapp -m todoapp
   ```
2. Migrated the virtual environment and uv Python 3.12 runtime into `/home/todoapp/apps/todoapp/.venv` and `/home/todoapp/.local/share/uv/python/cpython-3.12.8-linux-x86_64-gnu/`.
3. Adjusted SELinux security contexts: Executable binaries in `/home/todoapp` were labeled `bin_t` (`sudo chcon -R -t bin_t ...`) to permit execution by systemd (`init_t`) while SELinux remains in `Enforcing` mode.
4. Set ownership and file permissions:
   - `/home/todoapp/apps/todoapp`: `todoapp:todoapp` (`0750`)
   - `/home/todoapp/apps/todoapp/app/.env`: `todoapp:todoapp` (`0600`)
5. Installed hardened `/etc/systemd/system/todoapp.service` containing sandbox isolation directives:
   `NoNewPrivileges=true`, `PrivateTmp=true`, `PrivateDevices=true`, `ProtectKernelTunables=true`, `ProtectKernelModules=true`, `ProtectControlGroups=true`, `MemoryHigh=128M`, `MemoryMax=192M`.
6. Started and enabled service: `systemctl enable --now todoapp.service`.

### Stage 4: Application Security Remediations Deployed
Transferred and installed audited remediation source files into `/home/todoapp/apps/todoapp/app/TodoApp/`:
- `rate_limiter.py` (`0644`, `todoapp:todoapp`): High-performance thread-safe sliding-window rate limiter protecting `/auth/login` (10 req/min/IP) and `/auth/register` (5 req/min/IP) with standard `Retry-After` HTTP headers.
- `main.py` (`0644`, `todoapp:todoapp`): Suppressed `/docs`, `/redoc`, and `/openapi.json` interactive API documentation when `ENVIRONMENT=production`. Added `csrf_cookie_middleware` attaching HMAC-signed session cookies.
- `routers/auth.py` (`0644`, `todoapp:todoapp`): Unconditional double-submit HMAC-SHA256 CSRF verification on form submissions. Missing or tampered tokens result in immediate `HTTP 403 Forbidden`.
- `.env` (`0600`, `todoapp:todoapp`): Configured `ENVIRONMENT=production`, `COOKIE_SECURE=true`, `ACCESS_TOKEN_EXPIRE_MINUTES=60`, preserving original `SECRET_KEY` and Neon PostgreSQL `DATABASE_URL`.

### Stage 5: Reverse Proxy Hardening & Automated TLS
Deployed hardened `/etc/caddy/Caddyfile`:
1. **Canonical Block (`todo.veyrion.in`)**:
   - Automated Let's Encrypt TLSv1.3 certificate acquisition and renewal.
   - Upstream reverse proxy: `127.0.0.1:8000` (`header_up Host {host}`, `header_up X-Real-IP {remote_host}`).
   - Server banners suppressed: `-Server` on both response and upstream reverse-proxy headers.
   - Comprehensive security headers:
     - `Strict-Transport-Security: max-age=86400`
     - `X-Frame-Options: DENY`
     - `X-Content-Type-Options: nosniff`
     - `Referrer-Policy: strict-origin-when-cross-origin`
     - `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; form-action 'self'; frame-ancestors 'none'; object-src 'none'; base-uri 'self';`
     - `Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=()`
   - Dedicated access logging: `/var/log/caddy/todo.veyrion.in.access.log` (JSON format, 20 MB rotation, 5 kept generations).
2. **Legacy Migration Block (`80-225-229-214.sslip.io`)**:
   - `redir https://todo.veyrion.in{uri} permanent` (`HTTP 301`).
3. **Plaintext HTTP Catch-All (`:80`)**:
   - `redir https://todo.veyrion.in{uri} permanent` (`HTTP 301/308`).
4. Validated and safely reloaded:
   ```bash
   caddy validate --config /etc/caddy/Caddyfile
   systemctl reload caddy.service
   ```

---

## 4. Production Verification Results Matrix

The live verification test suite was executed against the production server over the public internet. All 28 checks passed with zero errors:

| Check Category | Test Description | Observed Result | Status |
| :--- | :--- | :--- | :--- |
| **TLS & PKI** | Issuer Certificate Authority | Let's Encrypt (`CN=YE2`) | **PASS** |
| **TLS & PKI** | Negotiated Protocol & Cipher | TLSv1.3 (`TLS_AES_128_GCM_SHA256`) | **PASS** |
| **TLS & PKI** | Subject Alternative Name (SAN) | `DNS:todo.veyrion.in` | **PASS** |
| **TLS & PKI** | Certificate Validity Range | Nov 19, 2026 &rarr; Feb 17, 2027 GMT | **PASS** |
| **Redirects** | Legacy Host `https://80-225-229-214.sslip.io/` | `HTTP 301` &rarr; `https://todo.veyrion.in/` | **PASS** |
| **Redirects** | Plaintext IP `http://80.225.229.214/` | `HTTP 301` &rarr; `https://todo.veyrion.in/` | **PASS** |
| **Redirects** | Plaintext Domain `http://todo.veyrion.in/` | `HTTP 308` &rarr; `https://todo.veyrion.in/` | **PASS** |
| **Security Headers** | `Strict-Transport-Security` | `max-age=86400` | **PASS** |
| **Security Headers** | `X-Frame-Options` | `DENY` | **PASS** |
| **Security Headers** | `X-Content-Type-Options` | `nosniff` | **PASS** |
| **Security Headers** | `Content-Security-Policy` | `frame-ancestors 'none'` | **PASS** |
| **Security Headers** | `Referrer-Policy` | `strict-origin-when-cross-origin` | **PASS** |
| **Banner Suppression** | `Server` Header | Fully stripped (empty, no uvicorn/caddy) | **PASS** |
| **API Docs Disabled** | Swagger UI (`/docs`) | `HTTP 404 Not Found` | **PASS** |
| **API Docs Disabled** | ReDoc (`/redoc`) | `HTTP 404 Not Found` | **PASS** |
| **API Docs Disabled** | OpenAPI Schema (`/openapi.json`) | `HTTP 404 Not Found` | **PASS** |
| **CSRF Protection** | Missing form token on `/auth/login` | `HTTP 403 Forbidden` | **PASS** |
| **CSRF Protection** | Tampered token signature on `/auth/login` | `HTTP 403 Forbidden` | **PASS** |
| **User Lifecycle** | User Registration (`/auth/register`) | `HTTP 200 OK` (User created) | **PASS** |
| **User Lifecycle** | User Authentication (`/auth/login`) | `HTTP 200 OK` (JWT cookie issued) | **PASS** |
| **User Lifecycle** | Create Todo (`POST /todos/add-todo`) | `HTTP 200 OK` (Created ID 5) | **PASS** |
| **Tenant Isolation** | User B Dashboard View | Alice's todo hidden from Bob | **PASS** |
| **Tenant Isolation** | User B Direct Edit Request (`/todos/edit-todo/5`) | Blocked (`HTTP 302` &rarr; `Todo not found`) | **PASS** |
| **Tenant Isolation** | User B Direct Delete Request (`/todos/delete/5`) | Blocked (`HTTP 302` &rarr; `Todo not found`) | **PASS** |
| **User Lifecycle** | Update & Mark Complete (`/todos/edit-todo/5`) | `HTTP 200 OK` (Marked complete) | **PASS** |
| **User Lifecycle** | Delete Todo (`POST /todos/delete/5`) | `HTTP 200 OK` (Deleted) | **PASS** |
| **User Lifecycle** | Confirm Deleted from Dashboard | `HTTP 200 OK` (Dashboard empty) | **PASS** |
| **Rate Limiting** | Burst threshold on `/auth/login` | `HTTP 429 Too Many Requests` (`Retry-After: 60`) | **PASS** |

---

## 5. Database Integrity & Data Preservation

The production PostgreSQL database connection (`neondb_owner@ep-mute-waterfall...`) was preserved intact without schema alterations.

Pre-existing application records were directly queried on the production server following deployment to verify absolute data preservation:

```text
Database Record Count: Users=5, Todos=1
  User ID 8: supdhhh@gmail.com (supdhhh@gmail.com), role=user, active=True  [PRE-EXISTING PRESERVED]
  User ID 9: verify_a_1795094918@veyrion.in, role=user, active=True         [TEST USER]
  User ID 10: verify_b_1795094918@veyrion.in, role=user, active=True        [TEST USER]
  User ID 11: audit_a_1795095189@veyrion.in, role=user, active=True         [AUDIT USER A]
  User ID 12: audit_b_1795095189@veyrion.in, role=user, active=True         [AUDIT USER B]
  Todo ID 4: "finish task", owner_id=8, complete=True                       [PRE-EXISTING PRESERVED]
```

**Verdict**: Pre-existing user `supdhhh@gmail.com` and pre-existing todo item `"finish task"` are 100% intact.

---

## 6. Security Posture Comparison

| Security Control | Pre-Deployment State | Post-Deployment Hardened State |
| :--- | :--- | :--- |
| **Canonical URL** | `https://80-225-229-214.sslip.io` | `https://todo.veyrion.in` |
| **Port 80 Insecure Traffic** | Plaintext reverse-proxy to FastAPI | `HTTP 301` Permanent Redirect to HTTPS |
| **Service Execution User** | `opc` (Interactive admin user, shell access) | `todoapp` (System account, `/sbin/nologin`, sandboxed) |
| **Memory Limit Enforcement** | Unlimited (OOM risk on 1 GB RAM shape) | Systemd cgroup `MemoryHigh=128M`, `MemoryMax=192M` |
| **CSRF Verification** | Conditional (bypassed if cookie omitted) | Mandatory HMAC-SHA256 double-submit check (`HTTP 403`) |
| **Brute-Force Protection** | None (unlimited login & register attempts) | In-memory sliding window rate limiter (`HTTP 429`) |
| **Interactive API Docs** | Publicly accessible at `/docs`, `/openapi.json` | Disabled in production (`HTTP 404 Not Found`) |
| **Information Disclosure** | `Server: uvicorn` header leaked | Stripped (`Server` header empty) |
| **Defensive Headers** | Missing HSTS, XFO, nosniff, CSP | Full security header suite enforced via Caddy |
| **SELinux** | Enforcing (unconfined home execution) | Enforcing with `bin_t` execution contexts |

---

## 7. System Health, Ports & Resource Consumption

### Systemd Services Status
- `todoapp.service`: **active (running)**, **enabled** (PID 144795)
- `caddy.service`: **active (running)**, **enabled** (PID 57063)
- `firewalld.service`: **active (running)**, **enabled**

### Network Socket Bindings (`ss -tulpn`)
```text
udp   UNCONN 0      0          *:443        *:*    users:(("caddy",pid=57063,fd=7))
tcp   LISTEN 0      2048   127.0.0.1:8000   *:*    users:(("uvicorn",pid=144795,fd=6))  <-- STRICT LOOPBACK
tcp   LISTEN 0      128      0.0.0.0:22     *:*    users:(("sshd",pid=2112,fd=7))
tcp   LISTEN 0      4096           *:443    *:*    users:(("caddy",pid=57063,fd=10))
tcp   LISTEN 0      4096           *:80     *:*    users:(("caddy",pid=57063,fd=13))
tcp   LISTEN 0      128         [::]:22     *:*    users:(("sshd",pid=2112,fd=8))
```
*Note: Port 8000 is exclusively bound to `127.0.0.1` and is completely inaccessible from the public internet.*

### Resource Utilization (VM.Standard.E2.1.Micro)
- **RAM**: 945 MiB total | 550 MiB used | 395 MiB available
- **Swap**: 944 MiB total | 276 MiB used | 668 MiB free
- **Root Filesystem**: 30 GiB total | 6.5 GiB used | 23 GiB available (22% utilization)
- **Uvicorn Process RSS**: ~103.6 MiB (Well within `MemoryHigh=128M` boundary)
- **Caddy Process RSS**: ~57.5 MiB

---

## 8. Portfolio Server Isolation Confirmation

In accordance with strict operational guardrails, the engineering portfolio server was isolated and remained untouched throughout the deployment:

- **Portfolio IP**: `140.238.230.200`
- **Domain**: `https://veyrion.in/`
- **Verified Status**: `HTTP/2 200 OK` (Serving static portfolio with full security headers)
- **Redirect Status**: `https://www.veyrion.in/` &rarr; `HTTP/2 301` to `https://veyrion.in/`
- **Zero Connections / Zero Changes Made to 140.238.230.200**.

---

## 9. Rollback Procedure

If emergency rollback is ever required, all pre-deployment artifacts are preserved in `[REDACTED_BACKUP_PATH]` on `80.225.229.214`.

To restore the pre-deployment state:

```bash
# 1. Connect to OCI TodoApp Server
ssh -i <ssh-identity-key> -o IdentitiesOnly=yes opc@80.225.229.214

# 2. Stop the new service account
sudo systemctl stop todoapp.service

# 3. Restore Caddyfile and reload Caddy
sudo cp [REDACTED_BACKUP_PATH] /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy.service

# 4. Restore original systemd service
sudo cp [REDACTED_BACKUP_PATH] /etc/systemd/system/todoapp.service
sudo systemctl daemon-reload

# 5. Restore application code and .env in /home/opc/apps/todoapp/
sudo tar -xzf [REDACTED_BACKUP_PATH] -C /home/opc/apps/todoapp/
sudo cp [REDACTED_BACKUP_PATH] /home/opc/apps/todoapp/app/.env

# 6. Restart the legacy service
sudo systemctl start todoapp.service
sudo systemctl status todoapp.service
```

---

## 10. Conclusion & Final Sign-Off

The TodoApp production hardening and migration to `https://todo.veyrion.in/` is **COMPLETE and SIGNED OFF**.

The service operates securely under unprivileged credentials, with automatic TLS certificates, strict CSRF validation, brute-force mitigation, defensive security headers, seamless legacy URL redirection, and full tenant isolation.
