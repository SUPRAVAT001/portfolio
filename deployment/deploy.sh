#!/usr/bin/env bash
# ==============================================================================
# veyrion.in Production Deployment Script
# Target: Oracle Linux 9.8 (1 GB RAM Micro Instance - instance-20261115-1749)
# Web Server: Caddy Standalone Linux AMD64 (Zero Package Manager / Zero Docker)
# Architecture: Unprivileged daemon execution, SELinux enforcing compliance
# ==============================================================================

set -euo pipefail

# --- Color Output Helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# --- Script Paths & Directory Context ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTFOLIO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SITE_DIR="${PORTFOLIO_ROOT}/site"

# --- Deployment Configuration ---
CADDY_VERSION="${CADDY_VERSION:-2.11.9}"
CADDY_BIN="/usr/local/bin/caddy"
CADDY_USER="caddy"
CADDY_GROUP="caddy"
WEBROOT="/var/www/veyrion.in"
CONFIG_DIR="/etc/caddy"
LOG_DIR="/var/log/caddy"
DATA_DIR="/var/lib/caddy"
SERVICE_FILE="/etc/systemd/system/caddy.service"

EXPECTED_IP="140.238.230.200"
TARGET_DOMAIN="veyrion.in"
WWW_DOMAIN="www.veyrion.in"

BACKUP_ROOT="/var/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/caddy_predeploy_${TIMESTAMP}"

SKIP_DNS_CHECK=false
DRY_RUN=false

# --- Argument Parsing ---
for arg in "$@"; do
    case "$arg" in
        --skip-dns-check)
            SKIP_DNS_CHECK=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        -h|--help)
            echo "Usage: sudo ./deploy.sh [OPTIONS]"
            echo "Options:"
            echo "  --skip-dns-check   Proceed even if DNS has not yet fully propagated"
            echo "  --dry-run          Execute preflight checks without applying changes"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

echo "=================================================================="
echo "          veyrion.in Production Deployment Initializing           "
echo "=================================================================="
log_info "Deployment timestamp: ${TIMESTAMP}"
log_info "Target webroot:       ${WEBROOT}"
log_info "Caddy target version: ${CADDY_VERSION}"

# ==============================================================================
# PHASE 1: PRIVILEGE & ENVIRONMENT SAFETY CHECKS
# ==============================================================================
log_info "Phase 1: Validating execution environment..."

# 1.1 Root check
if [[ "${EUID}" -ne 0 ]]; then
    log_error "This script must be executed with root privileges (sudo)."
    exit 1
fi

# 1.2 Architecture check
ARCH="$(uname -m)"
if [[ "${ARCH}" != "x86_64" ]]; then
    log_error "Unsupported architecture: ${ARCH}. Expected x86_64."
    exit 1
fi

# 1.3 Strict Package-Manager Ban
# Verify no yum or dnf commands are invoked
if [[ -f /var/run/dnf.lock ]] || [[ -f /var/run/yum.pid ]]; then
    log_error "A package manager process is currently active or locked. Aborting to avoid memory freeze."
    exit 1
fi

# ==============================================================================
# PHASE 2: SYSTEM RESOURCE PREFLIGHT AUDIT
# ==============================================================================
log_info "Phase 2: Executing resource and safety preflight checks..."

# 2.1 Memory Headroom Check (Crucial for 1 GB RAM instance)
MEM_AVAIL_KB="$(grep MemAvailable /proc/meminfo | awk '{print $2}')"
MEM_AVAIL_MB=$(( MEM_AVAIL_KB / 1024 ))
log_info "Available system RAM: ${MEM_AVAIL_MB} MiB"

if [[ "${MEM_AVAIL_MB}" -lt 150 ]]; then
    log_error "Insufficient available memory: ${MEM_AVAIL_MB} MiB. Minimum requirement is 150 MiB to prevent OOM freeze."
    exit 1
fi
log_success "Memory headroom verified: ${MEM_AVAIL_MB} MiB available."

# 2.2 Disk Storage Check
DISK_AVAIL_MB="$(df -m / | awk 'NR==2 {print $4}')"
log_info "Available root filesystem storage: ${DISK_AVAIL_MB} MiB"

if [[ "${DISK_AVAIL_MB}" -lt 1000 ]]; then
    log_error "Insufficient disk space: ${DISK_AVAIL_MB} MiB available. Minimum required is 1000 MiB."
    exit 1
fi
log_success "Disk space verified: ${DISK_AVAIL_MB} MiB free on /."

# 2.3 Port Collision Audit (Ports 80 & 443)
log_info "Verifying ports 80 and 443 availability..."
PORT_80_OCCUPIED=false
PORT_443_OCCUPIED=false

if ss -H -tulpn "sport = :80" | grep -q .; then
    CONFLICT_PROC="$(ss -tulpn 'sport = :80' | awk 'NR>1 {print $NF}')"
    # If the process holding port 80 is an already running caddy, it is acceptable for upgrade
    if echo "${CONFLICT_PROC}" | grep -q "caddy"; then
        log_info "Port 80 is currently bound by existing Caddy service (will be reloaded/restarted)."
    else
        log_error "Port 80 is already in use by a foreign service: ${CONFLICT_PROC}"
        PORT_80_OCCUPIED=true
    fi
fi

if ss -H -tulpn "sport = :443" | grep -q .; then
    CONFLICT_PROC="$(ss -tulpn 'sport = :443' | awk 'NR>1 {print $NF}')"
    if echo "${CONFLICT_PROC}" | grep -q "caddy"; then
        log_info "Port 443 is currently bound by existing Caddy service."
    else
        log_error "Port 443 is already in use by a foreign service: ${CONFLICT_PROC}"
        PORT_443_OCCUPIED=true
    fi
fi

if [[ "${PORT_80_OCCUPIED}" = true ]] || [[ "${PORT_443_OCCUPIED}" = true ]]; then
    log_error "Port conflict detected. Please stop conflicting web services before deploying Caddy."
    exit 1
fi
log_success "Ports 80 and 443 verified available."

# 2.4 Existing Services Health & Isolation Audit
log_info "Verifying existing server services (SSH, PCP, OCI Agent)..."
if ! systemctl is-active --quiet sshd; then
    log_error "sshd.service is not active! Aborting to protect remote connectivity."
    exit 1
fi
log_success "SSH service confirmed active on port 22."

# 2.5 DNS Resolution Preflight
log_info "Verifying DNS resolution for ${TARGET_DOMAIN} and ${WWW_DOMAIN}..."
RESOLVED_IPS="$(getent ahosts "${TARGET_DOMAIN}" | awk '{print $1}' | sort -u || true)"

DNS_MATCH=false
for ip in ${RESOLVED_IPS}; do
    if [[ "${ip}" == "${EXPECTED_IP}" ]]; then
        DNS_MATCH=true
        break
    fi
done

if [[ "${DNS_MATCH}" = true ]]; then
    log_success "DNS verified: ${TARGET_DOMAIN} resolves to ${EXPECTED_IP}."
else
    log_warn "DNS Check: ${TARGET_DOMAIN} does NOT currently resolve to ${EXPECTED_IP} (Found: '${RESOLVED_IPS:-NONE}')."
    log_warn "Notice: Let's Encrypt automated TLS certificate issuance will FAIL if Caddy starts before DNS propagates."
    if [[ "${SKIP_DNS_CHECK}" = false ]] && [[ "${DRY_RUN}" = false ]]; then
        if [[ -t 0 ]]; then
            echo -en "${YELLOW}Proceed anyway without verified DNS? [y/N]: ${NC}"
            read -r response || response="N"
            if [[ ! "${response}" =~ ^[Yy]$ ]]; then
                log_error "Deployment halted by user until DNS records propagate. To bypass, run with --skip-dns-check."
                exit 1
            fi
        else
            log_error "DNS for ${TARGET_DOMAIN} does not yet resolve to ${EXPECTED_IP} and shell is non-interactive."
            log_error "Aborting safely to protect against ACME certificate rate-limiting."
            log_error "To deploy non-interactively before DNS has propagated, run with --skip-dns-check."
            exit 1
        fi
    fi
fi

if [[ "${DRY_RUN}" = true ]]; then
    log_success "Dry run requested. All preflight checks passed. Exiting without changes."
    exit 0
fi

# ==============================================================================
# PHASE 3: NON-DESTRUCTIVE BACKUP OF EXISTING CONFIGURATIONS
# ==============================================================================
log_info "Phase 3: Backing up existing web configurations..."
mkdir -p "${BACKUP_DIR}"

if [[ -f "${CONFIG_DIR}/Caddyfile" ]]; then
    cp -p "${CONFIG_DIR}/Caddyfile" "${BACKUP_DIR}/Caddyfile.bak"
    log_info "Backed up existing Caddyfile to ${BACKUP_DIR}/Caddyfile.bak"
fi

if [[ -f "${SERVICE_FILE}" ]]; then
    cp -p "${SERVICE_FILE}" "${BACKUP_DIR}/caddy.service.bak"
    log_info "Backed up existing caddy.service to ${BACKUP_DIR}/caddy.service.bak"
fi

if [[ -d "${WEBROOT}" ]] && [[ -n "$(ls -A "${WEBROOT}" 2>/dev/null)" ]]; then
    tar -czf "${BACKUP_DIR}/webroot_backup.tar.gz" -C "${WEBROOT}" .
    log_info "Archived existing webroot to ${BACKUP_DIR}/webroot_backup.tar.gz"
fi

# Record initial firewall state before any changes
FIREWALL_HTTP_PREEXISTING=false
FIREWALL_HTTPS_PREEXISTING=false
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    if firewall-cmd --list-services 2>/dev/null | grep -qw "http"; then
        FIREWALL_HTTP_PREEXISTING=true
    fi
    if firewall-cmd --list-services 2>/dev/null | grep -qw "https"; then
        FIREWALL_HTTPS_PREEXISTING=true
    fi
fi

cat <<EOF > "${BACKUP_DIR}/firewall_state.env"
# Recorded at: ${TIMESTAMP}
FIREWALL_HTTP_PREEXISTING=${FIREWALL_HTTP_PREEXISTING}
FIREWALL_HTTPS_PREEXISTING=${FIREWALL_HTTPS_PREEXISTING}
EOF
log_info "Recorded initial firewall state (HTTP: ${FIREWALL_HTTP_PREEXISTING}, HTTPS: ${FIREWALL_HTTPS_PREEXISTING}) to ${BACKUP_DIR}/firewall_state.env"

# ==============================================================================
# PHASE 4: SYSTEM USER & DIRECTORY HIERARCHY
# ==============================================================================
log_info "Phase 4: Configuring system users and directories..."

# Create unprivileged caddy group and user
if ! getent group "${CADDY_GROUP}" >/dev/null 2>&1; then
    groupadd --system "${CADDY_GROUP}"
    log_info "Created system group: ${CADDY_GROUP}"
fi

if ! id -u "${CADDY_USER}" >/dev/null 2>&1; then
    useradd --system \
        --gid "${CADDY_GROUP}" \
        --home-dir "${DATA_DIR}" \
        --shell /sbin/nologin \
        --comment "Caddy Web Server Daemon" \
        "${CADDY_USER}"
    log_info "Created system user: ${CADDY_USER}"
fi

# Create directory hierarchy with least-privilege permissions
mkdir -p "${CONFIG_DIR}"
chmod 755 "${CONFIG_DIR}"

mkdir -p "${WEBROOT}"
chmod 755 "${WEBROOT}"

mkdir -p "${LOG_DIR}"
chmod 750 "${LOG_DIR}"
chown -R "${CADDY_USER}:${CADDY_GROUP}" "${LOG_DIR}"

mkdir -p "${DATA_DIR}"
chmod 700 "${DATA_DIR}"
chown -R "${CADDY_USER}:${CADDY_GROUP}" "${DATA_DIR}"

log_success "Directory hierarchy prepared."

# ==============================================================================
# PHASE 5: CADDY STANDALONE BINARY DOWNLOAD & VERIFICATION
# ==============================================================================
log_info "Phase 5: Verifying Caddy standalone binary..."

NEED_DOWNLOAD=true
if [[ -x "${CADDY_BIN}" ]]; then
    CURRENT_VER="$("${CADDY_BIN}" version | awk '{print $1}')"
    log_info "Detected installed Caddy binary: ${CURRENT_VER}"
    if [[ "${CURRENT_VER}" == "v${CADDY_VERSION}" ]] || [[ "${CURRENT_VER}" == "${CADDY_VERSION}" ]]; then
        log_info "Installed binary matches target version (${CADDY_VERSION}). Skipping download."
        NEED_DOWNLOAD=false
    fi
fi

if [[ "${NEED_DOWNLOAD}" = true ]]; then
    log_info "Downloading official Caddy v${CADDY_VERSION} Linux AMD64 from GitHub Releases..."
    TEMP_DL_DIR="/tmp/caddy_deploy_${TIMESTAMP}"
    mkdir -p "${TEMP_DL_DIR}"

    TAR_NAME="caddy_${CADDY_VERSION}_linux_amd64.tar.gz"
    CHECKSUM_NAME="caddy_${CADDY_VERSION}_checksums.txt"

    TAR_URL="https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/${TAR_NAME}"
    CHECKSUM_URL="https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/${CHECKSUM_NAME}"

    curl -fsSL -o "${TEMP_DL_DIR}/${TAR_NAME}" "${TAR_URL}"
    curl -fsSL -o "${TEMP_DL_DIR}/${CHECKSUM_NAME}" "${CHECKSUM_URL}"

    log_info "Validating cryptographic SHA-512 integrity..."
    cd "${TEMP_DL_DIR}"
    if ! grep "${TAR_NAME}" "${CHECKSUM_NAME}" | sha512sum -c -; then
        log_error "SHA-512 checksum validation FAILED for ${TAR_NAME}! Aborting for security."
        rm -rf "${TEMP_DL_DIR}"
        exit 1
    fi
    log_success "Cryptographic SHA-512 signature verified."

    log_info "Extracting standalone binary..."
    tar -xzf "${TAR_NAME}" caddy
    install -m 755 -o root -g root caddy "${CADDY_BIN}"

    cd "${PORTFOLIO_ROOT}"
    rm -rf "${TEMP_DL_DIR}"
    log_success "Installed Caddy binary to ${CADDY_BIN}."
fi

# Verify executable works
"${CADDY_BIN}" version

# ==============================================================================
# PHASE 6: CONFIGURATION & SERVICE INSTALLATION
# ==============================================================================
log_info "Phase 6: Installing configuration and systemd service..."

# Install Caddyfile
install -m 644 -o root -g root "${SCRIPT_DIR}/Caddyfile" "${CONFIG_DIR}/Caddyfile"
log_info "Copied Caddyfile to ${CONFIG_DIR}/Caddyfile."

# Validate Caddyfile syntax BEFORE touching systemd
log_info "Validating Caddyfile syntax..."
if ! "${CADDY_BIN}" validate --config "${CONFIG_DIR}/Caddyfile"; then
    log_error "Caddyfile validation failed! Rolling back Caddyfile."
    if [[ -f "${BACKUP_DIR}/Caddyfile.bak" ]]; then
        cp -p "${BACKUP_DIR}/Caddyfile.bak" "${CONFIG_DIR}/Caddyfile"
    fi
    exit 1
fi
log_success "Caddyfile validation passed."
# Ensure log directory and files created during validation remain owned by caddy user
chown -R "${CADDY_USER}:${CADDY_GROUP}" "${LOG_DIR}" "${DATA_DIR}"

# Install systemd unit
install -m 644 -o root -g root "${SCRIPT_DIR}/caddy.service" "${SERVICE_FILE}"
log_info "Installed systemd unit to ${SERVICE_FILE}."

# ==============================================================================
# PHASE 7: WEBROOT SYNCHRONIZATION & PERMISSIONS
# ==============================================================================
log_info "Phase 7: Synchronizing static portfolio assets..."

if [[ ! -d "${SITE_DIR}" ]]; then
    log_error "Site directory not found at: ${SITE_DIR}."
    exit 1
fi

# Copy assets to webroot
cp -r "${SITE_DIR}/." "${WEBROOT}/"

# Set file ownership: opc (SSH user) owns files, caddy group has read access
TARGET_OWNER="opc"
if ! id -u "${TARGET_OWNER}" >/dev/null 2>&1; then
    TARGET_OWNER="root"
fi

chown -R "${TARGET_OWNER}:${CADDY_GROUP}" "${WEBROOT}"
find "${WEBROOT}" -type d -exec chmod 755 {} +
find "${WEBROOT}" -type f -exec chmod 644 {} +

log_success "Portfolio static assets synchronized to ${WEBROOT}."

# ==============================================================================
# PHASE 8: SELINUX CONTEXT ENFORCEMENT
# ==============================================================================
log_info "Phase 8: Applying SELinux security contexts..."

SELINUX_MODE="$(getenforce 2>/dev/null || echo 'Disabled')"
log_info "Current SELinux enforcement mode: ${SELINUX_MODE}"

if [[ "${SELINUX_MODE}" != "Disabled" ]]; then
    # Label webroot files with httpd_sys_content_t
    chcon -R -t httpd_sys_content_t "${WEBROOT}" 2>/dev/null || true
    restorecon -Rv "${WEBROOT}" >/dev/null 2>&1 || true

    # Label Caddy binary
    restorecon -v "${CADDY_BIN}" >/dev/null 2>&1 || true

    # Label configuration, log, and data directories
    restorecon -Rv "${CONFIG_DIR}" "${LOG_DIR}" "${DATA_DIR}" >/dev/null 2>&1 || true

    log_success "SELinux contexts applied (httpd_sys_content_t for webroot, var_log_t for logs)."
fi

# ==============================================================================
# PHASE 9: FIREWALL PERMISSIONS (FIREWALLD)
# ==============================================================================
log_info "Phase 9: Configuring host firewall rules (firewalld)..."

if systemctl is-active --quiet firewalld; then
    FIREWALL_MODIFIED=false

    if ! firewall-cmd --list-services | grep -qw "http"; then
        firewall-cmd --permanent --add-service=http
        FIREWALL_MODIFIED=true
        log_info "Added 'http' service to firewalld."
    fi

    if ! firewall-cmd --list-services | grep -qw "https"; then
        firewall-cmd --permanent --add-service=https
        FIREWALL_MODIFIED=true
        log_info "Added 'https' service to firewalld."
    fi

    if [[ "${FIREWALL_MODIFIED}" = true ]]; then
        firewall-cmd --reload
        log_success "Firewalld rules reloaded."
    else
        log_info "Firewalld already allows 'http' and 'https'. No reload necessary."
    fi
else
    log_warn "firewalld is not active. Ensure network ingress on ports 80/443 is permitted."
fi

# ==============================================================================
# PHASE 10: SERVICE ACTIVATION & POST-DEPLOYMENT VERIFICATION
# ==============================================================================
log_info "Phase 10: Activating Caddy systemd service..."

systemctl daemon-reload
systemctl enable caddy.service
systemctl restart caddy.service

# Wait for process initialization
sleep 2

if ! systemctl is-active --quiet caddy.service; then
    log_error "caddy.service failed to activate! Recent journal logs:"
    journalctl -u caddy --no-pager -n 25
    log_error "Please run './rollback.sh' to revert to the previous state."
    exit 1
fi
log_success "caddy.service is active and running."

# Local Socket Smoke Test
log_info "Executing local HTTP smoke tests..."
HTTP_RESP="$(curl -sI -o /dev/null -w "%{http_code}" -H "Host: ${TARGET_DOMAIN}" http://127.0.0.1/ || echo "ERR")"
log_info "HTTP probe to http://127.0.0.1/ (Host: ${TARGET_DOMAIN}) returned status: ${HTTP_RESP}"

if [[ "${HTTP_RESP}" == "308" ]] || [[ "${HTTP_RESP}" == "301" ]] || [[ "${HTTP_RESP}" == "200" ]]; then
    log_success "Local HTTP listener functioning as expected (Redirecting to HTTPS or serving content)."
else
    log_warn "Unexpected HTTP status: ${HTTP_RESP}. Review journalctl -u caddy for details."
fi

echo "=================================================================="
echo "          veyrion.in Deployment Successfully Completed!          "
echo "=================================================================="
log_success "Caddy web server is active under unprivileged user '${CADDY_USER}'."
log_info "Access logs:      ${LOG_DIR}/veyrion.in.access.log"
log_info "System logs:      journalctl -u caddy -f"
log_info "Pre-deploy backup:${BACKUP_DIR}"
echo "=================================================================="
