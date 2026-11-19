# TodoApp Domain Migration & Production Deployment Report

**Deployment Date**: November 19, 2026  
**Status**: **DEPLOYED TO PRODUCTION & PUBLISHED TO GIT**  
**Portfolio Canonical URL**: [https://veyrion.in/](https://veyrion.in/)  
**TodoApp Canonical URL**: [https://todo.veyrion.in/](https://todo.veyrion.in/)  
**Portfolio Server**: Oracle Cloud Infrastructure (OCI) — `140.238.230.200` (`/var/www/veyrion.in`)  
**Git Repository**: `git@github.com:SUPRAVAT001/portfolio.git` (`branch: main`)

---

## 1. Executive Summary

Following explicit user authorization, the **TodoApp production domain migration** was deployed to the live Veyrion portfolio production server (`140.238.230.200`) and committed/pushed to the GitHub repository.

All live application links, buttons, metadata entries, and screenshot lightbox captions across the portfolio website now point to **`https://todo.veyrion.in/`**. The legacy hostname (`80-225-229-214.sslip.io`) has been completely eradicated from the deployed webroot.

Live HTTPS verification confirmed that both production applications (**Veyrion Portfolio** at `https://veyrion.in/` and **TodoApp** at `https://todo.veyrion.in/`) are healthy, secure, and fully operational.

---

## 2. Modified Files & Exact Changes

Only two files were modified, with 8 insertions and 8 deletions:

### File 1: `site/projects/index.html`
- **Line 139**: Updated TodoApp card action button `Live Demo ↗`:
  ```html
  <a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" style="color: #4ade80; font-weight: 600; font-size: 0.85rem;">Live Demo ↗</a>
  ```

### File 2: `site/projects/todoapp/index.html`
- **Line 130**: Hero callout text:
  ```html
  https://todo.veyrion.in · TLSv1.3 Encrypted · Caddy Reverse Proxy
  ```
- **Line 133**: Hero primary CTA button `Launch Live App ↗`:
  ```html
  <a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" class="btn btn-primary" style="padding: 10px 22px; font-size: 0.92rem; font-weight: 600;">Launch Live App ↗</a>
  ```
- **Line 154**: Screenshot gallery login lightbox caption:
  ```html
  data-caption="Live Production Login Interface (https://todo.veyrion.in/auth/login): Dual session authentication with CSRF protection"
  ```
- **Line 160**: Screenshot gallery API docs lightbox caption:
  ```html
  data-caption="Live Swagger / OpenAPI Documentation (https://todo.veyrion.in/docs): Interactive JSON REST API endpoints"
  ```
- **Line 272**: Sidebar "Project Metadata" public URL row:
  ```html
  <span class="project-sidebar-val"><a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" style="color: #4ade80;">todo.veyrion.in ↗</a></span>
  ```
- **Line 313**: Sidebar primary action button `Launch Live App ↗`:
  ```html
  <a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" class="btn btn-primary" style="justify-content: center; font-weight: 600;">Launch Live App ↗</a>
  ```
- **Line 316**: Sidebar secondary action button `Open API Docs (/docs) ↗`:
  ```html
  <a href="https://todo.veyrion.in/docs" target="_blank" rel="noopener noreferrer" class="btn btn-secondary" style="justify-content: center;">Open API Docs (/docs) ↗</a>
  ```

---

## 3. Server Backup Archive

Prior to overwriting any files on `140.238.230.200`, a full archive of `/var/www/veyrion.in` was captured:

- **Host**: `140.238.230.200`
- **Backup Path**: `[REDACTED_BACKUP_PATH]`
- **Archive Size**: 2.4 MB
- **Creation Timestamp**: `2026-11-19 13:53:40 GMT`
- **Contents**: Full snapshot of previous webroot before domain migration.

---

## 4. Production Webroot Synchronization

The updated website files were transferred via `rsync` over SSH into a staging directory `/tmp/site_update/` on `140.238.230.200`, synchronized into `/var/www/veyrion.in/`, and secured:

1. **Synchronization Command**:
   ```bash
   sudo rsync -av --delete /tmp/site_update/ /var/www/veyrion.in/
   ```
2. **Permissions & Ownership**:
   - Ownership: `caddy:caddy`
   - Directory permissions: `0755` (`find /var/www/veyrion.in -type d -exec chmod 755 {} +`)
   - File permissions: `0644` (`find /var/www/veyrion.in -type f -exec chmod 644 {} +`)
3. **SELinux Security Context**:
   - Context: `unconfined_u:object_r:httpd_sys_content_t:s0` applied via `sudo restorecon -Rv /var/www/veyrion.in`.
4. **Deployed Webroot Zero-Old-Hostname Verification**:
   - `grep -rn '80-225-229-214' /var/www/veyrion.in/` &rarr; **0 matches**
   - `grep -rn 'sslip' /var/www/veyrion.in/` &rarr; **0 matches**

---

## 5. Git Publication Record

- **Branch**: `main`
- **Commit Hash**: `5a10c2ef66a02900e0fbdf0bca4292eab251dfe6` (Short: `5a10c2e`)
- **Commit Message**:
  ```text
  Update TodoApp production domain to todo.veyrion.in
  ```
- **Files Committed**:
  - `site/projects/index.html` (2 lines changed)
  - `site/projects/todoapp/index.html` (14 lines changed)
- **Remote Configured**: `origin` (`git@github.com:SUPRAVAT001/portfolio.git`)
- **Push Command**: `git push origin main`
- **Push Status**: **SUCCESS** (`99b9311..5a10c2e main -> main`)

---

## 6. Live Production Verification (22/22 Checks Passed)

All endpoints and assets were probed live over public HTTPS:

| Target Endpoint | HTTP Status | Content-Type | Result |
| :--- | :--- | :--- | :--- |
| `https://veyrion.in/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/projects/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/projects/todoapp/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/projects/devops-jarvis/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/projects/git-argo/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/projects/kube-obs/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/about/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/contact/` | `HTTP/2 200 OK` | `text/html; charset=utf-8` | **PASS** |
| `https://veyrion.in/css/style.css` | `HTTP/2 200 OK` | `text/css; charset=utf-8` | **PASS** |
| `https://veyrion.in/js/main.js` | `HTTP/2 200 OK` | `text/javascript; charset=utf-8` | **PASS** |
| `https://veyrion.in/resume/Supravat_Dash_Resume.pdf` | `HTTP/2 200 OK` | `application/pdf` (80.8 KB) | **PASS** |
| `https://veyrion.in/images/profile.jpg` | `HTTP/2 200 OK` | `image/jpeg` (330 KB) | **PASS** |

### Live Content Verifications:
- `https://veyrion.in/projects/todoapp/`:
  - **Zero old hostname matches**: `80-225-229-214` & `sslip.io` absent.
  - **Hero CTA**: `<a href="https://todo.veyrion.in/" ...>` verified.
  - **Hero Callout Text**: `https://todo.veyrion.in · TLSv1.3 Encrypted · Caddy Reverse Proxy` verified.
  - **Sidebar Public URL**: `<a href="https://todo.veyrion.in/" ...>todo.veyrion.in ↗</a>` verified.
  - **Sidebar API Docs**: `<a href="https://todo.veyrion.in/docs" ...>` verified.
- `https://veyrion.in/projects/`:
  - **Live Demo ↗ Button**: `<a href="https://todo.veyrion.in/" ...>` verified.
  - **Zero old hostname matches**: `80-225-229-214` absent.

---

## 7. Confirmation of Operational Status for Both Applications

1. **Veyrion Portfolio (`https://veyrion.in/`)**:
   - Host: OCI `140.238.230.200`
   - Status: **HEALTHY & VERIFIED** (`HTTP/2 200 OK`)
   - HTTPS: Automated Let's Encrypt TLSv1.3 active
   - Canonical Redirect: `https://www.veyrion.in/` &rarr; `HTTP/2 301` to `https://veyrion.in/`
2. **TodoApp (`https://todo.veyrion.in/`)**:
   - Host: OCI `80.225.229.214`
   - Status: **HEALTHY & VERIFIED** (`HTTP/2 302` &rarr; `HTTP/2 200 OK` on `/auth/login`)
   - HTTPS: Automated Let's Encrypt TLSv1.3 active
   - Database: Intact (All users and todos preserved)
   - Service account: Running under sandboxed `todoapp:todoapp` (`PID 144795`)
   - Legacy Redirect: `https://80-225-229-214.sslip.io/` &rarr; `HTTP 301` to `https://todo.veyrion.in/`

---

## 8. Compliance with Operational Guardrails

- **TodoApp server (`80.225.229.214`)**: Untouched during this deployment.
- **TodoApp database (PostgreSQL Neon)**: Untouched during this deployment.
- **Portfolio Caddy configuration**: Untouched (no restart or Caddyfile edits required).
- **SSH settings**: Preserved on port 22 on both instances.
- **Unrelated projects**: Zero modifications to Devops-Jarvis, Git-Argo, or Kube-Obs.
