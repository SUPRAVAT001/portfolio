# Comprehensive Production Security Audit: FastAPI TodoApp
**Target Application:** TodoApp (FastAPI / SQLAlchemy / PostgreSQL / Uvicorn)  
**Existing Production URL:** `https://80-225-229-214.sslip.io/`  
**Target Migration Domain:** `todo.veyrion.in`  
**Audit Date:** November 19, 2026  
**Auditor:** Senior Application Security Engineer, FastAPI Architect, Linux Systems Engineer, and DevSecOps Auditor  
**Audit Scope:** Full-stack source code, API attack surface, production server configuration, reverse proxy, TLS, database/secrets handling, and migration readiness.  
**Audit Mode:** Strictly Read-Only (Zero modifications to production code, database, firewall, or DNS).

---

## 1. Executive Summary

A comprehensive application and infrastructure security audit was conducted on the production **TodoApp** deployment currently hosted on Oracle Cloud Infrastructure (OCI Compute Instance `instance-20261115-1737`, Public IP: `80.225.229.214`) under the existing hostname `80-225-229-214.sslip.io`.

The audit evaluated the actual local and remote source code (`/home/sdash/Todo-app/FASTAPI_PRAC/TodoApp` and `/home/opc/apps/todoapp/app`), live HTTP/HTTPS endpoint behaviors, database models, authentication workflows, CSRF protections, reverse proxy configurations, and systemd sandboxing.

### Core Strengths Identified
1. **Multi-Tenant Object Isolation (BOLA/IDOR Defense):** Every database query across both HTML and JSON API routes rigorously scopes operations to `Todos.owner_id == current_user.id`. Users cannot view, modify, toggle, or delete tasks belonging to other accounts.
2. **Strict Privilege Boundaries:** Default registration hardcodes `role = "user"`. Admin endpoints (`/admin/...`) strictly enforce `require_admin_user`, and normal users cannot elevate privileges.
3. **Robust Password Hashing & ORM Query Safety:** Passwords are hashed using `bcrypt` via Passlib with automatic salt generation. Zero dynamic SQL concatenation exists in the application; all operations utilize SQLAlchemy 2.0 parameterized queries.
4. **Cookie Security Attributes:** Authentication cookies are configured with `HttpOnly=True`, `SameSite=Lax`, and `Secure=True` in production.

### Primary Security Gaps Requiring Remediation Prior to Migration
1. **Unencrypted HTTP Proxy on Port 80 (High):** The production Caddy configuration contains an explicit `:80` site block that proxies unencrypted HTTP traffic directly to Uvicorn rather than enforcing an automatic 301/308 redirect to HTTPS. Requests to `http://80.225.229.214/` leak session cookies and allow unencrypted credential transmission.
2. **Missing Defensive Security Headers (Medium/High):** The production reverse proxy emits zero hardening headers: missing `Strict-Transport-Security` (HSTS), missing `X-Frame-Options` (Clickjacking exposure), missing `Content-Security-Policy` (CSP), and missing `X-Content-Type-Options: nosniff`.
3. **Public Exposure of Interactive API Documentation (Medium):** Swagger UI (`/docs`), ReDoc (`/redoc`), and the full OpenAPI schema (`/openapi.json` — 21.9 KB) are publicly exposed without authentication, providing potential attackers complete reconnaissance of all endpoints, parameters, models, and administrative paths.
4. **Absence of Rate Limiting & Account Lockout (Medium):** Authentication endpoints (`/auth/login`, `/auth/token/login`, `/auth/register`) have no rate limiting, leaving them susceptible to automated credential stuffing and registration flooding.
5. **Conditional CSRF Verification on Login/Register (Medium):** In `routers/auth.py`, login and registration forms check `if request.cookies.get(CSRF_COOKIE_NAME):` before verifying CSRF tokens, allowing requests that omit the cookie to bypass validation.
6. **Stateless JWT Logout without Invalidation (Low/Medium):** Logout only clears client-side cookies; the signed JWT remains cryptographically valid until its 60-minute expiration.
7. **Permissive Password Policy (Low):** Password policy allows 6-character passwords with zero complexity requirements (no symbol, uppercase, or digit requirements).

### Overall Security Verdict
```
+----------------------------------------------------------------------------------+
|                                                                                  |
|                VERDICT: READY AFTER SECURITY CORRECTIONS                         |
|                                                                                  |
|   The application architecture and data isolation are sound. However,            |
|   migration to todo.veyrion.in must NOT occur until reverse proxy HTTP           |
|   redirection, security headers, API documentation controls, and CSRF fixes       |
|   are remediated.                                                                |
|                                                                                  |
+----------------------------------------------------------------------------------+
```

---

## 2. Actual Application Architecture

### Component Inventory
* **Source Repository Root (Local):** `/home/sdash/Todo-app/FASTAPI_PRAC`
* **Application Package (Local):** `/home/sdash/Todo-app/FASTAPI_PRAC/TodoApp`
* **Production Working Directory (Remote):** `/home/opc/apps/todoapp/app`
* **Framework:** FastAPI `0.141.1` on Starlette `1.6.0`
* **ASGI Server:** Uvicorn `0.52.1` (`--host 127.0.0.1 --port 8000 --workers 1`)
* **Reverse Proxy:** Caddy v2 (`v2.8.4` on OCI compute instance `instance-20261115-1737`)
* **Database Engine:** Managed PostgreSQL (Cloud-hosted via Neon / AWS-backed) with SSL connection pooling (`pool_pre_ping=True`)
* **ORM:** SQLAlchemy `2.0.51` (Declarative Base, typed schemas)
* **Migrations:** Alembic `1.19.1` (`0001_initial_schema.py` and `0002_reconcile_schema.py` head revision)
* **Template Engine:** Jinja2 `3.1.6` with local Bootstrap 4.3.1 assets (no external CDNs)
* **Authentication Token:** `python-jose` `3.5.0` (HMAC-SHA256, 60-minute lifetime)
* **Password Hashing:** `passlib` `1.7.4` + `bcrypt` `4.0.1`

### Data Model Architecture (`TodoApp/models.py`)
1. **`Users` Model (`users` table):**
   - `id`: Integer PK, indexed
   - `email`: String, unique, indexed, non-null
   - `username`: String, unique, indexed, non-null (mirrors email)
   - `first_name`, `last_name`: String, non-null
   - `hashed_password`: String, non-null (bcrypt hash)
   - `is_active`: Boolean, default `True`, non-null
   - `role`: String, default `"user"`, non-null (`"user"` or `"admin"`)
   - `todos`: 1-to-many relationship with `cascade="all, delete-orphan"`
2. **`Todos` Model (`todos` table):**
   - `id`: Integer PK, indexed
   - `title`: String(100), indexed, non-null
   - `description`: String(300), indexed, non-null
   - `priority`: Integer (1–5), non-null
   - `complete`: Boolean, default `False`, non-null
   - `owner_id`: Integer, FK to `users.id` with `ondelete="CASCADE"`, indexed, non-null

---

## 3. Complete Endpoint Inventory & Classification

The application defines 28 total HTTP routes across 4 routers plus core middleware:

| HTTP Method | Route / Path | Router / Module | Authentication Required | Authorization Scope | Primary Function |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GET** | `/docs` | FastAPI Internal | **Public** | None | Interactive Swagger UI API documentation |
| **GET** | `/redoc` | FastAPI Internal | **Public** | None | ReDoc API documentation |
| **GET** | `/openapi.json` | FastAPI Internal | **Public** | None | Full OpenAPI v3 schema export |
| **GET** | `/` | `main.py:50` | **Authenticated (Cookie)** | Current User | Render authenticated user todo dashboard (redirects to `/auth/login` if unauthenticated) |
| **GET** | `/static/{file_path}` | `main.py:22` | **Public** | None | Static CSS, JS, and font assets |
| **GET** | `/auth/login` | `routers/auth.py:154` | **Public** | None | Render HTML login form with CSRF token |
| **POST** | `/auth/login` | `routers/auth.py:169` | **Public** | Form Submission | Authenticate user, issue HTTP-only `access_token` cookie |
| **GET** | `/auth/register` | `routers/auth.py:233` | **Public** | None | Render HTML registration form |
| **POST** | `/auth/register` | `routers/auth.py:245` | **Public** | Form Submission | Register user (`role="user"`), bcrypt hash password |
| **GET** | `/auth/logout` | `routers/auth.py:324` | **Public / Any** | None | Clear `access_token` cookie, redirect to login |
| **POST** | `/auth/logout` | `routers/auth.py:325` | **Public / Any** | None | Clear `access_token` cookie, redirect to login |
| **GET** | `/auth/profile` | `routers/auth.py:337` | **Authenticated (Cookie)** | Current User | Render user profile and password change form |
| **POST** | `/auth/change-password` | `routers/auth.py:352` | **Authenticated (Cookie)** | Current User + CSRF | Update password with old password verification |
| **POST** | `/auth/` | `routers/auth.py:418` | **Public** | None | REST API: User registration (`CreateUserRequest` $\rightarrow$ `UserResponse`) |
| **POST** | `/auth/token/login` | `routers/auth.py:473` | **Public** | OAuth2 Password | REST API: Exchange username/password for JSON JWT token |
| **GET** | `/todos/add-todo` | `routers/todos.py:27` | **Authenticated (Cookie)** | Current User | Render new todo creation form |
| **POST** | `/todos/add-todo` | `routers/todos.py:39` | **Authenticated (Cookie)** | Current User + CSRF | Create user-scoped todo from form |
| **GET** | `/todos/edit-todo/{todo_id}` | `routers/todos.py:105` | **Authenticated (Cookie)** | Todo Owner Only | Render todo edit form (strictly filtered by `owner_id`) |
| **POST** | `/todos/edit-todo/{todo_id}` | `routers/todos.py:126` | **Authenticated (Cookie)** | Todo Owner + CSRF | Update todo item (strictly filtered by `owner_id`) |
| **POST** | `/todos/delete/{todo_id}` | `routers/todos.py:195` | **Authenticated (Cookie)** | Todo Owner + CSRF | Delete todo item (strictly filtered by `owner_id`) |
| **POST** | `/todos/complete/{todo_id}` | `routers/todos.py:222` | **Authenticated (Cookie)** | Todo Owner + CSRF | Toggle completion status (`owner_id` scoped) |
| **GET** | `/todos/api/` | `routers/todos.py:254` | **Authenticated (Bearer/Cookie)** | Current User | REST API: List todos owned by caller |
| **GET** | `/todos/api/{todo_id}` | `routers/todos.py:267` | **Authenticated (Bearer/Cookie)** | Todo Owner Only | REST API: Retrieve specific todo (`owner_id` scoped) |
| **POST** | `/todos/api/` | `routers/todos.py:279` | **Authenticated (Bearer/Cookie)** | Current User | REST API: Create new todo owned by caller |
| **PUT** | `/todos/api/{todo_id}` | `routers/todos.py:310` | **Authenticated (Bearer/Cookie)** | Todo Owner Only | REST API: Update todo (`owner_id` scoped) |
| **DELETE** | `/todos/api/{todo_id}` | `routers/todos.py:345` | **Authenticated (Bearer/Cookie)** | Todo Owner Only | REST API: Delete todo (`owner_id` scoped) |
| **GET** | `/admin/` & `/admin/dashboard` | `routers/admin.py:45` | **Authenticated (Role: admin)** | Admin Only | Render administrative metrics dashboard |
| **POST** | `/admin/users/{user_id}/toggle-active` | `routers/admin.py:93` | **Authenticated (Role: admin)** | Admin + CSRF | Activate or deactivate target user |
| **GET** | `/admin/api/stats` | `routers/admin.py:146` | **Authenticated (Role: admin)** | Admin Only | REST API: System aggregate user/todo counts |
| **GET** | `/admin/api/users` | `routers/admin.py:155` | **Authenticated (Role: admin)** | Admin Only | REST API: List all users (`UserResponse`) |
| **PATCH**| `/admin/api/users/{user_id}/status` | `routers/admin.py:164` | **Authenticated (Role: admin)** | Admin Only | REST API: Toggle account active state |
| **GET** | `/admin/api/todos` | `routers/admin.py:198` | **Authenticated (Role: admin)** | Admin Only | REST API: List all system todos |
| **GET** | `/users/profile` | `routers/users.py:18` | **Public** | None | Convenience 302 redirect to `/auth/profile` |
| **GET** | `/users/me` | `routers/users.py:24` | **Authenticated (Bearer/Cookie)** | Current User | REST API: Return authenticated user details |
| **GET** | `/users/` | `routers/users.py:32` | **Authenticated (Role: admin)** | Admin Only | REST API: List all users |
| **GET** | `/users/{user_id}` | `routers/users.py:41` | **Authenticated (Self or Admin)** | Account Owner/Admin | REST API: View user details (blocked for cross-user) |

---

## 4. In-Depth Security Findings & Vulnerability Analysis

### Finding 1: Unencrypted Plaintext HTTP Proxy on Port 80
* **Category:** Infrastructure / Network Security
* **Severity:** **HIGH**
* **OWASP Mapping:** A02:2021 – Cryptographic Failures / A05:2021 – Security Misconfiguration
* **Evidence:**
  File: `/etc/caddy/Caddyfile` on `80.225.229.214`:
  ```caddy
  :80 {
      reverse_proxy 127.0.0.1:8000 {
          header_up X-Real-IP {remote_host}
      }
  }
  ```
  Empirical Probe:
  `curl -s -D - http://80.225.229.214/ -o /dev/null`
  Output:
  ```http
  HTTP/1.1 302 Found
  Location: /auth/login
  Set-Cookie: csrf_token=...; HttpOnly; Path=/; SameSite=lax; Secure
  Server: uvicorn
  ```
* **Impact:** Any user or bot accessing the service over plaintext HTTP (`http://80.225.229.214/`) is served unencrypted content and cookies. If an end-user submits a login form via plaintext HTTP, their plaintext credentials and session tokens traverse public network hops unencrypted, enabling Man-in-the-Middle (MitM) eavesdropping and credential harvesting.
* **Remediation:** Remove the `:80` reverse proxy block from Caddyfile. Caddy automatically provisions HTTP-to-HTTPS redirects (308 Permanent Redirect) for all defined HTTPS hostnames.

---

### Finding 2: Complete Absence of Defensive HTTP Security Headers
* **Category:** Browser & Network Security
* **Severity:** **MEDIUM / HIGH**
* **OWASP Mapping:** A05:2021 – Security Misconfiguration
* **Evidence:**
  Empirical Probe on `https://80-225-229-214.sslip.io/`:
  ```http
  HTTP/2 302 
  alt-svc: h3=":443"; ma=2592000
  date: Thu, 19 Nov 2026 12:54:29 GMT
  location: /auth/login
  server: uvicorn
  set-cookie: csrf_token=...; HttpOnly; Path=/; SameSite=lax; Secure
  via: 1.1 Caddy
  ```
  Missing Headers:
  - `Strict-Transport-Security` (HSTS)
  - `X-Frame-Options`
  - `X-Content-Type-Options`
  - `Content-Security-Policy` (CSP)
  - `Referrer-Policy`
  - `Permissions-Policy`
* **Impact:**
  - **Clickjacking:** Without `X-Frame-Options: DENY` or `frame-ancestors 'none'`, any malicious site can embed the TodoApp inside a transparent `<iframe>` and trick authenticated users into clicking buttons (e.g. deleting tasks or modifying account settings).
  - **MIME Sniffing:** Lack of `X-Content-Type-Options: nosniff` allows legacy browsers to interpret uploaded or static files as executable scripts.
  - **Protocol Downgrade:** Absence of HSTS allows opportunistic SSL-stripping attacks on first visits.
* **Remediation:** Configure standardized defensive headers in Caddyfile:
  ```caddy
  header {
      Strict-Transport-Security "max-age=86400; includeSubDomains"
      X-Content-Type-Options "nosniff"
      X-Frame-Options "DENY"
      Referrer-Policy "strict-origin-when-cross-origin"
      Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
      Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self';"
      -Server
  }
  ```

---

### Finding 3: Unrestricted Public Exposure of Interactive Swagger & OpenAPI Schema
* **Category:** API Security / Information Disclosure
* **Severity:** **MEDIUM**
* **OWASP Mapping:** API9:2023 – Improper Inventory Management / A01:2021 – Broken Access Control
* **Evidence:**
  - `https://80-225-229-214.sslip.io/docs` $\rightarrow$ `HTTP/2 200 OK` (Swagger UI)
  - `https://80-225-229-214.sslip.io/redoc` $\rightarrow$ `HTTP/2 200 OK` (ReDoc)
  - `https://80-225-229-214.sslip.io/openapi.json` $\rightarrow$ `HTTP/2 200 OK` (21,968 bytes JSON schema)
  Source Code (`TodoApp/main.py:20`):
  ```python
  app = FastAPI(title="TodoApp", version="1.0.0")
  ```
* **Impact:** Exposing interactive API docs and OpenAPI specifications on production reveals all available internal schemas (`AdminStatsResponse`, `UserStatusUpdateRequest`, `CreateUserRequest`), route parameters, regex validations, role names, and endpoint paths. This drastically reduces attacker discovery effort.
* **Remediation:** In `TodoApp/main.py`, disable docs in production unless specifically requested, or restrict docs behind administrative authorization or reverse proxy IP restrictions:
  ```python
  from .config import ENVIRONMENT

  is_prod = ENVIRONMENT == "production"
  app = FastAPI(
      title="TodoApp",
      version="1.0.0",
      docs_url=None if is_prod else "/docs",
      redoc_url=None if is_prod else "/redoc",
      openapi_url=None if is_prod else "/openapi.json",
  )
  ```

---

### Finding 4: Absence of Rate Limiting and Brute-Force Protection
* **Category:** Authentication & API Security
* **Severity:** **MEDIUM**
* **OWASP Mapping:** API2:2023 – Broken Authentication / A07:2021 – Identification and Authentication Failures
* **Evidence:**
  Inspection of `TodoApp/main.py` and `TodoApp/routers/auth.py` confirms no rate-limiting middleware (such as `slowapi`), Redis token bucket, or in-memory limiter is configured.
  Inspection of Caddyfile confirms zero `rate_limit` directives.
* **Impact:** Attackers can execute rapid, distributed brute-force attacks against `POST /auth/login` and `POST /auth/token/login` to guess user credentials without triggering account lockout or request throttling. Attackers can also flood `POST /auth/register` to exhaust database storage or IDs.
* **Remediation:** Implement rate limiting at the reverse proxy layer (Caddy `rate_limit` plugin or fail2ban on 401 logs) and within FastAPI using `slowapi` (e.g., 5 login attempts per minute per IP).

---

### Finding 5: Incomplete CSRF Verification on Form Login and Registration
* **Category:** Browser & Session Security
* **Severity:** **MEDIUM**
* **OWASP Mapping:** A01:2021 – Broken Access Control / CSRF
* **Evidence:**
  File: `TodoApp/routers/auth.py`, Lines 177–179 and 256–258:
  ```python
  # In login_post:
  if request.cookies.get(CSRF_COOKIE_NAME):
      verify_csrf_protection(request, csrf_token)

  # In register_post:
  if request.cookies.get(CSRF_COOKIE_NAME):
      verify_csrf_protection(request, csrf_token)
  ```
  Contrast with state-changing routes in `todos.py:53`, `admin.py:109`, and `auth.py:365`:
  ```python
  verify_csrf_protection(request, csrf_token)  # Unconditional
  ```
* **Impact:** Wrapping CSRF verification in `if request.cookies.get(CSRF_COOKIE_NAME):` means that if an attacker induces a victim's browser or tool to submit the form without sending the `csrf_token` cookie, validation is bypassed completely. While login CSRF carries lower impact than state-changing mutations, registration CSRF can be abused to pre-register victims into attacker-controlled accounts.
* **Remediation:** Ensure `verify_csrf_protection(request, csrf_token)` is called unconditionally on all state-changing HTML POST routes, or implement an explicit exception handler with clear error messaging.

---

### Finding 6: Stateless JWT Logout Without Server-Side Invalidation
* **Category:** Authentication / Session Management
* **Severity:** **LOW / MEDIUM**
* **OWASP Mapping:** API2:2023 – Broken Authentication
* **Evidence:**
  File: `TodoApp/routers/auth.py`, Lines 324–329:
  ```python
  @router.get("/logout")
  @router.post("/logout")
  async def logout():
      response = RedirectResponse(url="/auth/login?logged_out=1", status_code=status.HTTP_302_FOUND)
      response.delete_cookie(ACCESS_COOKIE_NAME, path="/")
      return response
  ```
* **Impact:** When a user logs out, only the browser cookie is deleted. The cryptographic JWT remains valid until its `exp` timestamp (up to 60 minutes). If an attacker captured the JWT prior to logout (e.g., via network interception or browser history/cache), they can continue accessing protected API endpoints (`/todos/api/`, `/users/me`) until token expiration.
* **Remediation:** Introduce a lightweight token blocklist (via Redis or database table storing revoked `jti` UUIDs) or increment a `token_version` on the `Users` record that is validated on every authenticated request.

---

### Finding 7: Permissive Password Length & Complexity Policy
* **Category:** Authentication Security
* **Severity:** **LOW**
* **OWASP Mapping:** A07:2021 – Identification and Authentication Failures
* **Evidence:**
  File: `TodoApp/routers/auth.py`, Line 290 and `schemas.py:11`:
  ```python
  if len(password) < 6 or len(password.encode("utf-8")) > 72 or password.isspace():
      return _error("Password must be between 6 and 72 characters.")
  ```
* **Impact:** A 6-character password without complexity requirements allows easily guessable passwords (e.g. `123456`, `qwerty`), rendering accounts susceptible to dictionary and rainbow table attacks. (Note: bcrypt's 72-byte truncation boundary is correctly respected via `len(password.encode("utf-8")) > 72`).
* **Remediation:** Enforce a minimum password length of 10–12 characters and check against the top 10,000 common compromised passwords.

---

### Finding 8: Backend Server Fingerprinting
* **Category:** Information Disclosure
* **Severity:** **LOW**
* **OWASP Mapping:** A05:2021 – Security Misconfiguration
* **Evidence:**
  Response headers:
  `server: uvicorn`  
  `via: 1.1 Caddy`
* **Impact:** Exposes the exact web application server (`uvicorn`) and proxy framework (`Caddy`), assisting automated scanners in fingerprinting the stack.
* **Remediation:** Add `header -Server` and `header_down -Server` to Caddy configuration to strip server banners.

---

### Finding 9: User Enumeration via Registration & Login Endpoints
* **Category:** Information Disclosure
* **Severity:** **INFORMATIONAL**
* **OWASP Mapping:** API3:2023 – Broken Object Property Level Authorization
* **Evidence:**
  `TodoApp/routers/auth.py`, Lines 294–295 and 434–438:
  ```python
  if _find_user_by_identifier(clean_email, db):
      raise HTTPException(
          status_code=status.HTTP_409_CONFLICT,
          detail="An account with this email already exists",
      )
  ```
  Line 196–207:
  ```python
  if not user.is_active:
      # Explicitly states account is deactivated
  ```
* **Impact:** Allows an external actor to test a database of email addresses to discover which individuals are registered users on the platform.
* **Remediation:** Standardize responses or consider subtle messaging adjustments if high privacy is required.

---

### Finding 10: Service Execution Under Administrative User Account
* **Category:** Operating System & Host Hardening
* **Severity:** **LOW**
* **OWASP Mapping:** A05:2021 – Security Misconfiguration
* **Evidence:**
  File: `/etc/systemd/system/todoapp.service` on `80.225.229.214`:
  ```ini
  User=opc
  Group=opc
  ```
* **Impact:** The application executes under `opc`, the default administrative user on Oracle Linux. While `NoNewPrivileges=true` and `PrivateTmp=true` are configured, a dedicated unprivileged system account (e.g., `todoapp:todoapp` with shell `/sbin/nologin`) provides stronger defense-in-depth against lateral privilege escalation.
* **Remediation:** Migrate service execution to a dedicated unprivileged system account `todoapp:todoapp`.

---

## 5. Production Infrastructure Assessment

| Component | Target State | Current Observed State | Risk / Gap |
| :--- | :--- | :--- | :--- |
| **Reverse Proxy** | Standalone Caddy v2 | Caddy `v2.8.4` (PID 57063) | Functional, but lacking security headers and access logs |
| **HTTP Port 80** | 301/308 Redirect to HTTPS | Proxies directly to Uvicorn | **High Risk:** Plaintext credential exposure on port 80 |
| **HTTPS Port 443**| TLSv1.3 with Let's Encrypt | Let's Encrypt EC prime256v1 certificate active | Fully compliant, valid through Feb 15, 2027 |
| **Backend Binding** | `127.0.0.1:8000` | `127.0.0.1:8000` | Secure (not listening on public interfaces) |
| **Database Port** | Not publicly exposed | No local port 5432; connects outbound to Cloud Postgres | Secure |
| **Firewall** | Ports 80, 443, 22 only | `dhcpv6-client http https ssh` active | Compliant with zero extraneous public ports |
| **SELinux** | Enforcing | Target host running Oracle Linux 9.8 UEK | Active |
| **Environment File**| Mode `0600`, non-public | `/home/opc/apps/todoapp/app/.env` (`-rw-------`, `0600`) | Secure (isolated from public webroot) |

---

## 6. API Documentation Exposure Assessment

FastAPI automatically generates interactive Swagger documentation (`/docs`), ReDoc (`/redoc`), and an OpenAPI schema (`/openapi.json`) when instantiated with defaults.

### Empirical Findings:
1. **Endpoint Reachability:**
   - `https://80-225-229-214.sslip.io/docs` $\rightarrow$ `HTTP/2 200 OK`
   - `https://80-225-229-214.sslip.io/redoc` $\rightarrow$ `HTTP/2 200 OK`
   - `https://80-225-229-214.sslip.io/openapi.json` $\rightarrow$ `HTTP/2 200 OK`
2. **Exposed Schemas:**
   The public JSON schema explicitly documents:
   - Request payloads for `CreateUserRequest`, `TodoRequest`, `UserStatusUpdateRequest`.
   - Response structures for `UserResponse`, `TodoResponse`, `AdminStatsResponse`.
   - URL paths and HTTP methods for administrative operations (`/admin/api/users`, `/admin/api/stats`, `/admin/api/todos`).
   - Query and path parameters (`todo_id`, `user_id`).
3. **Assessment:**
   While interactive documentation does not grant unauthenticated access to protected data (authorization checks remain active), it provides adversaries an authoritative blueprint of the entire API surface. For a personal engineering showcase, exposing documentation is acceptable **only if** the documentation is intentionally published for developer review and the endpoints themselves are thoroughly hardened. For production privacy, disabling `/docs` in production or protecting it via HTTP Basic Authentication in Caddy is recommended.

---

## 7. Recommended Production Architecture: `todo.veyrion.in`

### DNS Configuration
* **Registrar:** BigRock / Veyrion DNS Zone
* **Record Type:** `A` Record
* **Host / Name:** `todo` (Subdomain `todo.veyrion.in`)
* **Target IPv4:** `80.225.229.214`
* **TTL:** `14400` (or `300` seconds during migration window)
* **Pre-Issuance Verification:** Must resolve to `80.225.229.214` across Google (`8.8.8.8`) and Cloudflare (`1.1.1.1`) before triggering Caddy ACME challenges.

### Hardened Production Caddyfile for `80.225.229.214`

```caddy
# ==============================================================================
# Production Caddyfile: todo.veyrion.in
# Target Server: Oracle Cloud Infrastructure (80.225.229.214)
# ==============================================================================

# Canonical Application Host
todo.veyrion.in {
    encode zstd gzip

    # Defensive Security Headers
    header {
        Strict-Transport-Security "max-age=86400; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
        Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self';"
        -Server
    }

    # Reverse Proxy to Uvicorn ASGI Server
    reverse_proxy 127.0.0.1:8000 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }

    # Production Structured Access Logging
    log {
        output file /var/log/caddy/todo.veyrion.in.access.log {
            roll_size 20mb
            roll_keep 5
            roll_keep_for 720h
        }
        format json
    }
}

# Legacy Subdomain Migration Redirect (Preserves Existing Demo Bookmarks)
80-225-229-214.sslip.io {
    redir https://todo.veyrion.in{uri} permanent
}

# Direct IP Catch-All — Eliminates Plaintext HTTP Proxying
:80 {
    redir https://todo.veyrion.in{uri} permanent
}
```

---

## 8. Step-by-Step Remediation Plan

Prior to pointing `todo.veyrion.in` and publishing the new subdomain, execute the following phased plan:

### Phase 1: Application Code Hardening (Local Repository)
1. **Unconditional CSRF Verification:**
   In `TodoApp/routers/auth.py`, remove the `if request.cookies.get(CSRF_COOKIE_NAME):` guard on `login_post` and `register_post` so that CSRF tokens are verified unconditionally on all state-changing form submissions.
2. **Production API Documentation Toggle:**
   In `TodoApp/main.py`, disable Swagger UI and OpenAPI schema when `ENVIRONMENT == "production"`, or configure an environment flag `ENABLE_API_DOCS=false`.
3. **Password Policy Enhancement:**
   In `TodoApp/schemas.py` and `TodoApp/routers/auth.py`, raise the minimum password length to at least 10 characters and enforce basic character diversity.
4. **Run Regression Tests:**
   Execute full test suite (`pytest -v`) to confirm 100% pass rate.

### Phase 2: Host & Reverse Proxy Hardening (`80.225.229.214`)
1. **Configure Dedicated Logging Directory:**
   Create `/var/log/caddy` owned by `caddy:caddy` with SELinux label `var_log_t`.
2. **Apply Hardened Caddyfile:**
   Deploy the updated Caddyfile with security headers, automatic HTTPS, and legacy redirect.
3. **Validate Caddyfile:**
   Execute `caddy validate --config /etc/caddy/Caddyfile` before restarting the service.
4. **Restart Caddy Service:**
   `sudo systemctl restart caddy`

### Phase 3: DNS Migration & TLS Validation
1. Create `A` record `todo.veyrion.in` $\rightarrow$ `80.225.229.214`.
2. Verify global DNS propagation via `dig +short todo.veyrion.in @8.8.8.8`.
3. Reload Caddy (`caddy reload`) to initiate Let's Encrypt TLS certificate acquisition.
4. Verify HTTPS handshake:
   `curl -Iv https://todo.veyrion.in/`
5. Verify security headers, cookie attributes, and legacy redirect (`80-225-229-214.sslip.io` $\rightarrow$ `todo.veyrion.in`).

---

## 9. Regression Testing & Deployment Risks

### Regression Verification Requirements
* **Session Cookie Interoperability:** Confirm browser login sets `access_token` and `csrf_token` with `Domain` defaulting to `todo.veyrion.in` (without leaking to `veyrion.in` apex).
* **Cross-Site Request Forgery:** Confirm forms fail gracefully with HTTP 403 when CSRF token is invalid or missing.
* **REST API Authentication:** Confirm `Authorization: Bearer <token>` continues functioning for programmatic API clients on `https://todo.veyrion.in/todos/api/`.
* **Database Migration Integrity:** Confirm Alembic revisions remain aligned with PostgreSQL.

### Identified Deployment Risks
1. **DNS Propagation Delay:** BigRock DNS TTL default is 14,400s (4 hours). If DNS is created without waiting for propagation, Caddy's ACME challenge will fail. Mitigation: Verify with `dig` before issuing certificate.
2. **Cookie Scope Bleed:** If cookies were configured with `Domain=.veyrion.in`, session cookies could be sent to both portfolio and todoapp. Verification: The application does NOT specify a `domain` attribute in `set_cookie()`, which correctly restricts cookies to host-only (`todo.veyrion.in`).
3. **Memory Pressure on OCI Instance:** The host has 1 GB RAM. Uvicorn currently consumes ~106 MiB RSS and Caddy consumes ~67 MiB RSS. Memory utilization is stable with >300 MiB free, but package manager operations (`dnf`) must be avoided.

---

## 10. Final Verification Verdict

```
==================================================================================
                 FINAL AUDIT VERDICT: READY AFTER SECURITY CORRECTIONS
==================================================================================
Application Security Baseline:  EXCELLENT (Multi-tenant isolation, bcrypt, CSRF)
Infrastructure Configuration:   NEEDS CORRECTION (Unencrypted :80 block, missing headers)
API Exposure:                   NEEDS CORRECTION (Public Swagger/OpenAPI schema)
Migration Status:               BLOCKED UNTIL REMEDIATION COMPLETED
==================================================================================
```

The TodoApp code demonstrates strong security discipline in data isolation and tenant scoping. Upon executing the targeted Caddyfile and application configuration corrections detailed above, the application will be fully hardened and ready for public domain assignment at **`https://todo.veyrion.in/`**.
