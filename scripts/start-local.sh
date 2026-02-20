#!/usr/bin/env bash
#
# start-local.sh
# Starts all local services for the OPS Program Approval Demo.
#
# Stops existing backend/frontend processes, rebuilds the backend and frontend,
# then starts both services for local development and testing.
#
#   Backend:  Spring Boot on http://localhost:8080
#   Frontend: Vite dev server on http://localhost:3000 (proxies /api to backend)
#
# Usage:
#   ./scripts/start-local.sh                         # Full rebuild and start (H2 in-memory DB)
#   ./scripts/start-local.sh --skip-build            # Start without rebuilding
#   ./scripts/start-local.sh --backend-only          # Rebuild and start only the backend
#   ./scripts/start-local.sh --frontend-only         # Rebuild and start only the frontend
#   ./scripts/start-local.sh --use-azure-sql         # Start with Azure SQL backend
#   ./scripts/start-local.sh --use-azure-sql --backend-only --skip-build
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
FRONTEND_DIR="${ROOT_DIR}/frontend"
JAR_NAME="program-demo-0.4.0-SNAPSHOT.jar"
JAR_PATH="${BACKEND_DIR}/target/${JAR_NAME}"
BACKEND_PORT=8080
FRONTEND_PORT=3000
HEALTH_CHECK_URL="http://localhost:${BACKEND_PORT}/api/programs"
HEALTH_CHECK_TIMEOUT=60

# --- Defaults ---
SKIP_BUILD=false
BACKEND_ONLY=false
FRONTEND_ONLY=false
USE_AZURE_SQL=false

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build)    SKIP_BUILD=true;    shift ;;
        --backend-only)  BACKEND_ONLY=true;  shift ;;
        --frontend-only) FRONTEND_ONLY=true; shift ;;
        --use-azure-sql) USE_AZURE_SQL=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--skip-build] [--backend-only] [--frontend-only] [--use-azure-sql]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# --- Determine Spring Profile ---
if [[ "${USE_AZURE_SQL}" == true ]]; then
    SPRING_PROFILE="azuresql"
    DB_LABEL="Azure SQL (ActiveDirectoryDefault)"
else
    SPRING_PROFILE="local"
    DB_LABEL="H2 In-Memory"
fi

# --- Color Helpers ---
cyan()   { printf '\033[1;36m%s\033[0m\n' "$*"; }
green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
gray()   { printf '\033[0;37m%s\033[0m\n' "$*"; }

write_step() {
    echo ""
    cyan "========================================"
    cyan "  $1"
    cyan "========================================"
}

# --- Helper Functions ---

stop_process_on_port() {
    local port="$1"
    local service_name="$2"

    yellow "Checking for processes on port ${port} (${service_name})..."

    local pids
    pids=$(lsof -ti :"${port}" 2>/dev/null || true)

    if [[ -n "${pids}" ]]; then
        for pid in ${pids}; do
            local pname
            pname=$(ps -p "${pid}" -o comm= 2>/dev/null || echo "unknown")
            red "  Stopping ${pname} (PID: ${pid}) on port ${port}"
            kill -9 "${pid}" 2>/dev/null || true
            sleep 1
        done
        green "  Cleared port ${port}."
    else
        green "  Port ${port} is free."
    fi
}

wait_for_backend() {
    yellow "Waiting for backend to be ready..."
    local elapsed=0
    local interval=3

    while [[ ${elapsed} -lt ${HEALTH_CHECK_TIMEOUT} ]]; do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_CHECK_URL}" 2>/dev/null || echo "000")

        if [[ "${http_code}" == "200" ]]; then
            green "  Backend is ready! (HTTP ${http_code})"
            return 0
        fi

        gray "  Waiting... (${elapsed}/${HEALTH_CHECK_TIMEOUT} seconds)"
        sleep "${interval}"
        elapsed=$((elapsed + interval))
    done

    red "  WARNING: Backend did not respond within ${HEALTH_CHECK_TIMEOUT} seconds."
    red "  It may still be starting. Check the backend log."
    return 1
}

# --- Main Script ---

echo ""
echo "  OPS Program Approval Demo - Local Development"
echo "  ============================================="
echo "  Backend:  http://localhost:${BACKEND_PORT}"
echo "  Frontend: http://localhost:${FRONTEND_PORT}"
echo "  API Proxy: /api -> http://localhost:${BACKEND_PORT}"
echo "  Database: ${DB_LABEL}"
echo "  Profile:  ${SPRING_PROFILE}"
echo ""

# Azure CLI check when using Azure SQL
if [[ "${USE_AZURE_SQL}" == true && "${FRONTEND_ONLY}" == false ]]; then
    write_step "Verifying Azure CLI Login"
    if az account show --query '{name:name, user:user.name}' -o json &>/dev/null; then
        local_user=$(az account show --query 'user.name' -o tsv 2>/dev/null)
        local_sub=$(az account show --query 'name' -o tsv 2>/dev/null)
        green "  Logged in as: ${local_user}"
        green "  Subscription: ${local_sub}"
    else
        red "  ERROR: Not logged in to Azure CLI."
        red "  Run 'az login' first, then retry."
        exit 1
    fi

    yellow ""
    yellow "  Ensure your client IP is allowed in the Azure SQL firewall."
    yellow "  If connection fails, add your IP via Azure Portal or:"
    gray   "  az sql server firewall-rule create -g <rg> -s sql-ops-demo-dev-XYZ -n MyIP --start-ip-address <IP> --end-ip-address <IP>"
fi

# 1. Stop existing processes
write_step "Stopping existing processes"

if [[ "${FRONTEND_ONLY}" == false ]]; then
    stop_process_on_port "${BACKEND_PORT}" "Backend (Java)"
fi
if [[ "${BACKEND_ONLY}" == false ]]; then
    stop_process_on_port "${FRONTEND_PORT}" "Frontend (Vite/Node)"
fi

# Stop any orphaned java processes running the demo JAR
orphan_pids=$(pgrep -f "${JAR_NAME}" 2>/dev/null || true)
if [[ -n "${orphan_pids}" ]]; then
    for pid in ${orphan_pids}; do
        red "  Stopping orphaned Java process (PID: ${pid})"
        kill -9 "${pid}" 2>/dev/null || true
    done
fi

# 2. Build backend
if [[ "${FRONTEND_ONLY}" == false ]]; then
    if [[ "${SKIP_BUILD}" == false ]]; then
        write_step "Building Backend (Maven)"

        if [[ ! -d "${BACKEND_DIR}" ]]; then
            echo "ERROR: Backend directory not found: ${BACKEND_DIR}" >&2
            exit 1
        fi

        pushd "${BACKEND_DIR}" > /dev/null
        gray "Running: mvn clean package -DskipTests"
        mvn clean package -DskipTests
        green "  Backend build successful."
        popd > /dev/null
    else
        yellow "Skipping backend build (--skip-build)."
    fi

    # Verify JAR exists
    if [[ ! -f "${JAR_PATH}" ]]; then
        echo "ERROR: Backend JAR not found: ${JAR_PATH}. Run without --skip-build to build first." >&2
        exit 1
    fi
fi

# 3. Build frontend
if [[ "${BACKEND_ONLY}" == false ]]; then
    if [[ "${SKIP_BUILD}" == false ]]; then
        write_step "Installing Frontend Dependencies"

        if [[ ! -d "${FRONTEND_DIR}" ]]; then
            echo "ERROR: Frontend directory not found: ${FRONTEND_DIR}" >&2
            exit 1
        fi

        pushd "${FRONTEND_DIR}" > /dev/null
        if [[ ! -d "node_modules" ]]; then
            gray "Running: npm install"
            npm install
        else
            gray "  node_modules exists, skipping npm install."
        fi
        green "  Frontend dependencies ready."
        popd > /dev/null
    else
        yellow "Skipping frontend build (--skip-build)."
    fi
fi

# 4. Start backend
if [[ "${FRONTEND_ONLY}" == false ]]; then
    write_step "Starting Backend"
    gray "  JAR: ${JAR_PATH}"
    gray "  Profile: ${SPRING_PROFILE}"
    gray "  Database: ${DB_LABEL}"
    gray "  URL: http://localhost:${BACKEND_PORT}"

    # When using Azure SQL with ActiveDirectoryDefault, clear AZURE_CLIENT_*
    # env vars so DefaultAzureCredential falls through to AzureCliCredential.
    if [[ "${USE_AZURE_SQL}" == true ]]; then
        unset AZURE_CLIENT_ID AZURE_CLIENT_SECRET AZURE_TENANT_ID 2>/dev/null || true
        yellow "  Cleared AZURE_CLIENT_* env vars (using AzureCliCredential)"
    fi

    java -jar "${JAR_PATH}" --spring.profiles.active="${SPRING_PROFILE}" \
        > "${BACKEND_DIR}/backend.log" 2>&1 &
    BACKEND_PID=$!

    green "  Backend started (PID: ${BACKEND_PID})"

    # Wait for backend to be ready
    wait_for_backend || true

    if [[ "${BACKEND_ONLY}" == true ]]; then
        echo ""
        echo "  Backend is running. Use 'kill ${BACKEND_PID}' or run stop-local.sh to stop."
    fi
fi

# 5. Start frontend
if [[ "${BACKEND_ONLY}" == false ]]; then
    write_step "Starting Frontend"
    gray "  URL: http://localhost:${FRONTEND_PORT}"

    pushd "${FRONTEND_DIR}" > /dev/null
    npm run dev > "${FRONTEND_DIR}/frontend.log" 2>&1 &
    FRONTEND_PID=$!
    popd > /dev/null

    green "  Frontend started (PID: ${FRONTEND_PID})"
fi

# 6. Summary
write_step "All Services Started"

echo ""
echo "  Services Running:"
echo "  -----------------"
if [[ "${FRONTEND_ONLY}" == false ]]; then
    echo "  Backend API:  http://localhost:${BACKEND_PORT}/api/programs"
fi
if [[ "${BACKEND_ONLY}" == false ]]; then
    echo "  Frontend UI:  http://localhost:${FRONTEND_PORT}"
fi
echo ""
echo "  Backend log:  ${BACKEND_DIR}/backend.log"
echo "  Frontend log: ${FRONTEND_DIR}/frontend.log"
echo ""
echo "  To stop all services, run:"
echo "    ./scripts/stop-local.sh"
echo ""
