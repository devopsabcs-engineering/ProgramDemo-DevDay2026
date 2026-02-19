#!/usr/bin/env bash
#
# stop-local.sh
# Stops all local services for the OPS Program Approval Demo.
#
# Stops the backend (Java/Spring Boot) and frontend (Node/Vite) processes
# running on their default ports.
#

set -euo pipefail

BACKEND_PORT=8080
FRONTEND_PORT=3000
JAR_NAME="program-demo-0.4.0-SNAPSHOT.jar"

# --- Color Helpers ---
cyan()  { printf '\033[1;36m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }
gray()  { printf '\033[0;37m%s\033[0m\n' "$*"; }

cyan ""
cyan "Stopping OPS Program Approval Demo services..."
cyan ""

# Stop processes on backend port
backend_pids=$(lsof -ti :"${BACKEND_PORT}" 2>/dev/null || true)
if [[ -n "${backend_pids}" ]]; then
    for pid in ${backend_pids}; do
        pname=$(ps -p "${pid}" -o comm= 2>/dev/null || echo "unknown")
        red "  Stopping ${pname} (PID: ${pid}) on port ${BACKEND_PORT}"
        kill -9 "${pid}" 2>/dev/null || true
    done
else
    gray "  No process found on port ${BACKEND_PORT} (backend)."
fi

# Stop processes on frontend port
frontend_pids=$(lsof -ti :"${FRONTEND_PORT}" 2>/dev/null || true)
if [[ -n "${frontend_pids}" ]]; then
    for pid in ${frontend_pids}; do
        pname=$(ps -p "${pid}" -o comm= 2>/dev/null || echo "unknown")
        red "  Stopping ${pname} (PID: ${pid}) on port ${FRONTEND_PORT}"
        kill -9 "${pid}" 2>/dev/null || true
    done
else
    gray "  No process found on port ${FRONTEND_PORT} (frontend)."
fi

# Stop any orphaned java processes running the demo JAR
orphan_pids=$(pgrep -f "${JAR_NAME}" 2>/dev/null || true)
if [[ -n "${orphan_pids}" ]]; then
    for pid in ${orphan_pids}; do
        red "  Stopping orphaned Java process (PID: ${pid})"
        kill -9 "${pid}" 2>/dev/null || true
    done
fi

green ""
green "All services stopped."
green ""
