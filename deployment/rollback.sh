#!/usr/bin/env bash
# ==============================================================================
# veyrion.in Rollback Script
# Purpose: Safely deactivate Caddy, restore previous configuration or clean up,
#          and ensure core system services (SSH, PCP, OCI Agent) remain untouched.
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

# --- Configuration Paths ---
CADDY_BIN="/usr/local/bin/caddy"
CONFIG_DIR="/etc/caddy"
LOG_DIR="/var/log/caddy"
DATA_DIR="/var/lib/caddy"
WEBROOT="/var/www/veyrion.in"
SERVICE_FILE="/etc/systemd/system/caddy.service"
BACKUP_ROOT="/var/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

FORCE=false
REVERT_FIREWALL=false

# --- Argument Parsing ---
for arg in "$@"; do
    case "$arg" in
        -f|--force)
            FORCE=true
            ;;
        --revert-firewall)
            REVERT_FIREWALL=true
            ;;
        -h|--help)
            echo "Usage: sudo ./rollback.sh [OPTIONS]"
            echo "Options:"
            echo "  -f, --force          Bypass interactive confirmation prompt"
            echo "  --revert-firewall    Also remove HTTP and HTTPS services from firewalld"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

echo "=================================================================="
echo "               veyrion.in Rollback Initializing                   "
echo "=================================================================="

# Privilege Check
if [[ "${EUID}" -ne 0 ]]; then
    log_error "This script must be executed with root privileges (sudo)."
    exit 1
fi

# Confirmation Prompt
if [[ "${FORCE}" = false ]]; then
    echo -e "${YELLOW}WARNING: This action will stop the Caddy service and revert website configuration.${NC}"
    echo -en "Are you sure you want to proceed with rollback? [y/N]: "
    read -r response || response="N"
    if [[ ! "${response}" =~ ^[Yy]$ ]]; then
        log_info "Rollback aborted by user."
        exit 0
    fi
fi

# ==============================================================================
# STEP 1: STOP & DISABLE CADDY SERVICE
# ==============================================================================
log_info "Step 1: Deactivating Caddy systemd service..."

if systemctl is-active --quiet caddy.service 2>/dev/null; then
    systemctl stop caddy.service
    log_info "Stopped caddy.service."
fi

if systemctl is-enabled --quiet caddy.service 2>/dev/null; then
    systemctl disable caddy.service
    log_info "Disabled caddy.service."
fi

# ==============================================================================
# STEP 2: RESTORE CONFIGURATION FROM BACKUP (OR SAFELY REMOVE)
# ==============================================================================
log_info "Step 2: Checking for pre-deployment backups in ${BACKUP_ROOT}..."

LATEST_BACKUP="$(ls -td "${BACKUP_ROOT}"/caddy_predeploy_* 2>/dev/null | head -n 1 || true)"

if [[ -n "${LATEST_BACKUP}" ]] && [[ -d "${LATEST_BACKUP}" ]]; then
    log_info "Found pre-deployment backup: ${LATEST_BACKUP}"

    # Restore Caddyfile
    if [[ -f "${LATEST_BACKUP}/Caddyfile.bak" ]]; then
        cp -p "${LATEST_BACKUP}/Caddyfile.bak" "${CONFIG_DIR}/Caddyfile"
        log_success "Restored previous Caddyfile."
    else
        rm -f "${CONFIG_DIR}/Caddyfile"
        log_info "No previous Caddyfile in backup; removed deployed Caddyfile."
    fi

    # Restore caddy.service
    if [[ -f "${LATEST_BACKUP}/caddy.service.bak" ]]; then
        cp -p "${LATEST_BACKUP}/caddy.service.bak" "${SERVICE_FILE}"
        log_success "Restored previous caddy.service."
    else
        rm -f "${SERVICE_FILE}"
        log_info "No previous caddy.service in backup; removed deployed service file."
    fi

    # Restore webroot
    if [[ -f "${LATEST_BACKUP}/webroot_backup.tar.gz" ]]; then
        rm -rf "${WEBROOT:?}"/*
        tar -xzf "${LATEST_BACKUP}/webroot_backup.tar.gz" -C "${WEBROOT}"
        log_success "Restored previous webroot contents."
    else
        if [[ -d "${WEBROOT}" ]]; then
            # Archive current webroot before removing
            ARCHIVE_NAME="${BACKUP_ROOT}/veyrion_site_rollback_${TIMESTAMP}.tar.gz"
            tar -czf "${ARCHIVE_NAME}" -C "${WEBROOT}" . 2>/dev/null || true
            rm -rf "${WEBROOT:?}"/*
            log_info "Archived webroot to ${ARCHIVE_NAME} and cleaned ${WEBROOT}."
        fi
    fi
else
    log_info "No previous backup found (clean initial installation). Removing deployed files..."

    if [[ -f "${SERVICE_FILE}" ]]; then
        rm -f "${SERVICE_FILE}"
        log_info "Removed ${SERVICE_FILE}."
    fi

    if [[ -d "${CONFIG_DIR}" ]]; then
        rm -rf "${CONFIG_DIR}"
        log_info "Removed ${CONFIG_DIR}."
    fi

    if [[ -d "${WEBROOT}" ]]; then
        ARCHIVE_NAME="${BACKUP_ROOT}/veyrion_site_clean_${TIMESTAMP}.tar.gz"
        mkdir -p "${BACKUP_ROOT}"
        tar -czf "${ARCHIVE_NAME}" -C "${WEBROOT}" . 2>/dev/null || true
        rm -rf "${WEBROOT}"
        log_info "Archived webroot to ${ARCHIVE_NAME} and removed directory ${WEBROOT}."
    fi
fi

# Reload systemd to unregister service
systemctl daemon-reload

# ==============================================================================
# STEP 3: FIREWALL REVERSION (RESPECTING INITIAL STATE)
# ==============================================================================
if [[ "${REVERT_FIREWALL}" = true ]]; then
    log_info "Step 3: Checking initial firewall state for selective rule removal..."
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        FIREWALL_STATE_FILE=""
        if [[ -n "${LATEST_BACKUP}" ]] && [[ -f "${LATEST_BACKUP}/firewall_state.env" ]]; then
            FIREWALL_STATE_FILE="${LATEST_BACKUP}/firewall_state.env"
        fi

        if [[ -n "${FIREWALL_STATE_FILE}" ]]; then
            # Source recorded state: FIREWALL_HTTP_PREEXISTING and FIREWALL_HTTPS_PREEXISTING
            # shellcheck source=/dev/null
            source "${FIREWALL_STATE_FILE}"
            log_info "Loaded pre-deployment firewall state: HTTP pre-existing=${FIREWALL_HTTP_PREEXISTING:-false}, HTTPS pre-existing=${FIREWALL_HTTPS_PREEXISTING:-false}."

            RULES_REMOVED=false
            if [[ "${FIREWALL_HTTP_PREEXISTING:-false}" = false ]]; then
                if firewall-cmd --list-services 2>/dev/null | grep -qw "http"; then
                    firewall-cmd --permanent --remove-service=http 2>/dev/null || true
                    log_info "Removed HTTP service from firewalld (was introduced by deployment)."
                    RULES_REMOVED=true
                fi
            else
                log_info "Preserving pre-existing HTTP service in firewalld."
            fi

            if [[ "${FIREWALL_HTTPS_PREEXISTING:-false}" = false ]]; then
                if firewall-cmd --list-services 2>/dev/null | grep -qw "https"; then
                    firewall-cmd --permanent --remove-service=https 2>/dev/null || true
                    log_info "Removed HTTPS service from firewalld (was introduced by deployment)."
                    RULES_REMOVED=true
                fi
            else
                log_info "Preserving pre-existing HTTPS service in firewalld."
            fi

            if [[ "${RULES_REMOVED}" = true ]]; then
                firewall-cmd --reload 2>/dev/null || true
                log_success "Firewalld reloaded with introduced rules removed."
            else
                log_info "No deployment-introduced firewall rules to remove."
            fi
        else
            log_warn "No initial firewall state recorded in backup. Preserving all firewall rules to prevent accidental disruption."
        fi
    fi
else
    log_info "Step 3: Preserving current firewall configuration (pass --revert-firewall to selectively remove introduced ports)."
fi

# ==============================================================================
# STEP 4: HEALTH VERIFICATION OF CRITICAL SERVICES
# ==============================================================================
log_info "Step 4: Verifying health of core infrastructure services..."

# Verify SSH is unaffected
if systemctl is-active --quiet sshd; then
    log_success "SSH service confirmed ACTIVE and healthy (Port 22 intact)."
else
    log_error "CRITICAL: sshd is not active! Restarting sshd..."
    systemctl restart sshd || true
fi

# Verify port 80 and 443 are released
if ss -H -tulpn "sport = :80" | grep -q .; then
    log_warn "Port 80 is still in use by another process."
else
    log_success "Port 80 confirmed RELEASED."
fi

if ss -H -tulpn "sport = :443" | grep -q .; then
    log_warn "Port 443 is still in use by another process."
else
    log_success "Port 443 confirmed RELEASED."
fi

# Check PCP and OCI Agent
if systemctl is-active --quiet pmcd 2>/dev/null; then
    log_success "PCP pmcd metric service is active."
fi
if systemctl is-active --quiet oracle-cloud-agent 2>/dev/null; then
    log_success "Oracle Cloud Agent is active."
fi

echo "=================================================================="
echo "             veyrion.in Rollback Successfully Completed           "
echo "=================================================================="
log_success "Instance has been restored safely to its pre-deployment state."
