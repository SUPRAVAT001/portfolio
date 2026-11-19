# TodoApp Domain Link Migration Report

**Date**: November 19, 2026  
**Status**: **COMPLETED & VALIDATED (AWAITING APPROVAL TO DEPLOY TO PRODUCTION SERVER)**  
**Target Repository**: `/home/sdash/portfolio/`  
**Website Source**: `/home/sdash/portfolio/site/`  
**Old Live Application Host**: `https://80-225-229-214.sslip.io/`  
**New Live Application Host**: `https://todo.veyrion.in/`

---

## 1. Executive Summary

All live application links, buttons, metadata entries, and screenshot gallery captions for the **FastAPI TodoApp** within the local Veyrion engineering portfolio source have been updated to point to the canonical domain: **`https://todo.veyrion.in/`**.

A thorough audit of the entire portfolio source (`site/`) confirms that **exactly 0 occurrences of the old hostname (`80-225-229-214.sslip.io`) remain**.

### Why the Live Website (`https://veyrion.in/`) Currently Shows the Old Link
In the previous turn, the user request specified strict restrictions:
> *"Restrictions: Modify local portfolio files only. Do not connect to OCI. Do not modify DNS. Do not modify either production server. Do not commit or push. Stop after validation and await approval."*

Because of this explicit restriction, the changes were prepared, updated, and validated **locally in `/home/sdash/portfolio/site/` only**. They have **not yet been uploaded / synced to `/var/www/veyrion.in` on the OCI portfolio server (`140.238.230.200`)**. Once authorized, the updated files can be deployed to production in seconds.

---

## 2. Modified Files & Line-by-Line Changes

### File 1: `/home/sdash/portfolio/site/projects/index.html`

- **Location**: Line 139 (Projects catalog — TodoApp card action row)
- **Component**: "Live Demo ↗" external navigation button
- **Diff**:
  ```diff
  @@ -137,3 +137,3 @@
               <a href="/projects/todoapp/" class="text-link">Read Case Study →</a>
  -            <a href="https://80-225-229-214.sslip.io/" target="_blank" rel="noopener noreferrer" style="color: #4ade80; font-weight: 600; font-size: 0.85rem;">Live Demo ↗</a>
  +            <a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" style="color: #4ade80; font-weight: 600; font-size: 0.85rem;">Live Demo ↗</a>
             </div>
  ```

---

### File 2: `/home/sdash/portfolio/site/projects/todoapp/index.html`

- **Location 1**: Line 130 & 133 (Top hero callout banner)
- **Component**: Callout domain subtitle and primary "Launch Live App ↗" CTA button
- **Diff**:
  ```diff
  @@ -129,5 +129,5 @@
                 <div style="font-family: var(--font-mono); font-size: 0.82rem; color: var(--text-muted); margin-top: 2px;">
  -                https://80-225-229-214.sslip.io · TLSv1.3 Encrypted · Caddy Reverse Proxy
  +                https://todo.veyrion.in · TLSv1.3 Encrypted · Caddy Reverse Proxy
                 </div>
               </div>
  -            <a href="https://80-225-229-214.sslip.io/" target="_blank" rel="noopener noreferrer" class="btn btn-primary" style="padding: 10px 22px; font-size: 0.92rem; font-weight: 600;">
  +            <a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" class="btn btn-primary" style="padding: 10px 22px; font-size: 0.92rem; font-weight: 600;">
                 Launch Live App ↗
               </a>
  ```

- **Location 2**: Lines 154 & 160 (Screenshot Gallery Strip)
- **Component**: Captions displayed in lightbox viewer for login and API docs
- **Diff**:
  ```diff
  @@ -154,1 +154,1 @@
  - <div class="gallery-strip-thumb active" data-full="/images/todoapp/todoapp_login_live.png" data-caption="Live Production Login Interface (https://80-225-229-214.sslip.io/auth/login): Dual session authentication with CSRF protection">
  + <div class="gallery-strip-thumb active" data-full="/images/todoapp/todoapp_login_live.png" data-caption="Live Production Login Interface (https://todo.veyrion.in/auth/login): Dual session authentication with CSRF protection">
  @@ -160,1 +160,1 @@
  - <div class="gallery-strip-thumb" data-full="/images/todoapp/todoapp_api_docs_live.png" data-caption="Live Swagger / OpenAPI Documentation (https://80-225-229-214.sslip.io/docs): Interactive JSON REST API endpoints">
  + <div class="gallery-strip-thumb" data-full="/images/todoapp/todoapp_api_docs_live.png" data-caption="Live Swagger / OpenAPI Documentation (https://todo.veyrion.in/docs): Interactive JSON REST API endpoints">
  ```

- **Location 3**: Line 272 (Sidebar "Project Metadata" table)
- **Component**: "Public URL" metadata key value and anchor link
- **Diff**:
  ```diff
  @@ -271,3 +271,3 @@
               <span class="project-sidebar-key">Public URL</span>
  -            <span class="project-sidebar-val"><a href="https://80-225-229-214.sslip.io/" target="_blank" rel="noopener noreferrer" style="color: #4ade80;">80-225-229-214.sslip.io ↗</a></span>
  +            <span class="project-sidebar-val"><a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" style="color: #4ade80;">todo.veyrion.in ↗</a></span>
             </div>
  ```

- **Location 4**: Lines 313 & 316 (Sidebar CTA actions column)
- **Component**: Primary "Launch Live App ↗" and secondary "Open API Docs (/docs) ↗" action buttons
- **Diff**:
  ```diff
  @@ -312,5 +312,5 @@
             <div style="display: flex; flex-direction: column; gap: 10px;">
  -            <a href="https://80-225-229-214.sslip.io/" target="_blank" rel="noopener noreferrer" class="btn btn-primary" style="justify-content: center; font-weight: 600;">
  +            <a href="https://todo.veyrion.in/" target="_blank" rel="noopener noreferrer" class="btn btn-primary" style="justify-content: center; font-weight: 600;">
                 Launch Live App ↗
               </a>
  -            <a href="https://80-225-229-214.sslip.io/docs" target="_blank" rel="noopener noreferrer" class="btn btn-secondary" style="justify-content: center;">
  +            <a href="https://todo.veyrion.in/docs" target="_blank" rel="noopener noreferrer" class="btn btn-secondary" style="justify-content: center;">
                 Open API Docs (/docs) ↗
               </a>
  ```

---

## 3. Old and New URL Reference Mapping

| File Path | Element / Role | Old URL Reference | New URL Reference |
| :--- | :--- | :--- | :--- |
| `site/projects/index.html:139` | `<a href>` (Live Demo ↗) | `https://80-225-229-214.sslip.io/` | `https://todo.veyrion.in/` |
| `site/projects/todoapp/index.html:130` | `<div>` (Callout Subtitle) | `https://80-225-229-214.sslip.io` | `https://todo.veyrion.in` |
| `site/projects/todoapp/index.html:133` | `<a href>` (Launch Live App ↗) | `https://80-225-229-214.sslip.io/` | `https://todo.veyrion.in/` |
| `site/projects/todoapp/index.html:154` | `data-caption` (Login Screenshot) | `https://80-225-229-214.sslip.io/auth/login` | `https://todo.veyrion.in/auth/login` |
| `site/projects/todoapp/index.html:160` | `data-caption` (API Docs Screenshot) | `https://80-225-229-214.sslip.io/docs` | `https://todo.veyrion.in/docs` |
| `site/projects/todoapp/index.html:272` | `<a href>` (Public URL) | `https://80-225-229-214.sslip.io/` | `https://todo.veyrion.in/` |
| `site/projects/todoapp/index.html:272` | `<a>` Text (Sidebar Anchor) | `80-225-229-214.sslip.io ↗` | `todo.veyrion.in ↗` |
| `site/projects/todoapp/index.html:313` | `<a href>` (Launch Live App ↗) | `https://80-225-229-214.sslip.io/` | `https://todo.veyrion.in/` |
| `site/projects/todoapp/index.html:316` | `<a href>` (Open API Docs ↗) | `https://80-225-229-214.sslip.io/docs` | `https://todo.veyrion.in/docs` |

---

## 4. Remaining Old Hostname References

- **Inside `/home/sdash/portfolio/site/`**: **0 references**. Every single link, text label, and caption has been migrated.
- **Across the entire site source**: `grep -rn "80-225-229-214"` returns **0 matches**.

---

## 5. Deployment Options for Publishing Live to veyrion.in

Once approved by the user, publishing these changes live to `https://veyrion.in/` requires syncing the updated `site/` files to `/var/www/veyrion.in` on the portfolio server (`140.238.230.200`):

```bash
# Sync updated static site to portfolio server webroot
rsync -avz -e "ssh -i <ssh-identity-key> -o IdentitiesOnly=yes" \
  /home/sdash/portfolio/site/ opc@140.238.230.200:/tmp/site_update/

# Move into webroot and verify permissions on target host
ssh -i <ssh-identity-key> -o IdentitiesOnly=yes opc@140.238.230.200 \
  "sudo rsync -av --delete /tmp/site_update/ /var/www/veyrion.in/ && \
   sudo chown -R caddy:caddy /var/www/veyrion.in && \
   sudo restorecon -Rv /var/www/veyrion.in && \
   rm -rf /tmp/site_update"
```
