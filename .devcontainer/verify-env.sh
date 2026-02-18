#!/usr/bin/env bash
# ============================================================
# verify-env.sh — Verify all demo dependencies are installed
# Run this before the demo to confirm the environment is ready.
# Usage: bash .devcontainer/verify-env.sh
# ============================================================
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; ((PASS++)) || true; }
fail() { echo "  ❌ $1"; ((FAIL++)) || true; }
warn() { echo "  ⚠️  $1"; ((WARN++)) || true; }

check_command() {
  local cmd="$1"
  local label="${2:-$cmd}"
  if command -v "$cmd" &>/dev/null; then
    return 0
  else
    fail "$label not found"
    return 1
  fi
}

check_version() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  if [[ "$actual" == "$expected"* ]]; then
    pass "$label $actual"
  else
    fail "$label expected $expected.x, got $actual"
  fi
}

echo ""
echo "=== OPS Program Demo — Environment Verification ==="
echo ""

# -----------------------------------------------------------
# Java 21
# -----------------------------------------------------------
echo "Java:"
if check_command java "Java"; then
  JAVA_VER=$(java -version 2>&1 | head -1 | sed 's/.*"\(.*\)".*/\1/')
  check_version "$JAVA_VER" "21" "  JDK version"
fi

# -----------------------------------------------------------
# Maven 3.x
# -----------------------------------------------------------
echo "Maven:"
if check_command mvn "Maven"; then
  MVN_VER=$(mvn --version 2>&1 | head -1 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/Apache Maven \([^ ]*\).*/\1/')
  if [[ "$MVN_VER" == 3.* ]]; then
    pass "  Maven version $MVN_VER"
  else
    warn "  Maven version $MVN_VER (expected 3.x)"
  fi
fi

# -----------------------------------------------------------
# Node.js 20.x
# -----------------------------------------------------------
echo "Node.js:"
if check_command node "Node.js"; then
  NODE_VER=$(node --version | sed 's/^v//')
  check_version "$NODE_VER" "20" "  Node.js version"
fi

# -----------------------------------------------------------
# npm
# -----------------------------------------------------------
echo "npm:"
if check_command npm "npm"; then
  NPM_VER=$(npm --version)
  pass "  npm version $NPM_VER"
fi

# -----------------------------------------------------------
# Azure CLI
# -----------------------------------------------------------
echo "Azure CLI:"
if check_command az "Azure CLI"; then
  AZ_VER=$(az version --output tsv 2>/dev/null | head -1 | cut -f1)
  pass "  Azure CLI version $AZ_VER"
fi

# -----------------------------------------------------------
# GitHub CLI
# -----------------------------------------------------------
echo "GitHub CLI:"
if check_command gh "GitHub CLI"; then
  GH_VER=$(gh --version 2>&1 | head -1 | sed 's/gh version \([^ ]*\).*/\1/')
  pass "  GitHub CLI version $GH_VER"
fi

# -----------------------------------------------------------
# .NET SDK 8.x (for Azure Functions)
# -----------------------------------------------------------
echo ".NET SDK:"
if check_command dotnet ".NET SDK"; then
  DOTNET_VER=$(dotnet --version 2>/dev/null)
  check_version "$DOTNET_VER" "8" "  .NET SDK version"
fi

# -----------------------------------------------------------
# SQL Server tools (sqlcmd)
# -----------------------------------------------------------
echo "SQL Server tools:"
if command -v sqlcmd &>/dev/null; then
  SQLCMD_VER=$(sqlcmd --version 2>/dev/null | head -1 || echo "installed")
  pass "  sqlcmd $SQLCMD_VER"
elif [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
  SQLCMD_VER=$(/opt/mssql-tools18/bin/sqlcmd --version 2>/dev/null | head -1 || echo "installed")
  pass "  sqlcmd $SQLCMD_VER (at /opt/mssql-tools18/bin/sqlcmd)"
  warn "  sqlcmd not on PATH — add /opt/mssql-tools18/bin to PATH"
else
  fail "sqlcmd not found"
fi

# -----------------------------------------------------------
# Flyway CLI
# -----------------------------------------------------------
echo "Flyway:"
if check_command flyway "Flyway CLI"; then
  FLYWAY_VER=$(flyway --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "installed")
  pass "  Flyway version $FLYWAY_VER"
fi

# -----------------------------------------------------------
# Bicep CLI (via az bicep)
# -----------------------------------------------------------
echo "Bicep:"
if command -v az &>/dev/null; then
  BICEP_VER=$(az bicep version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "")
  if [ -n "$BICEP_VER" ]; then
    pass "  Bicep CLI version $BICEP_VER"
  else
    warn "  Bicep CLI not installed — run 'az bicep install'"
  fi
else
  fail "Bicep CLI requires Azure CLI"
fi

# -----------------------------------------------------------
# Git
# -----------------------------------------------------------
echo "Git:"
if check_command git "Git"; then
  GIT_VER=$(git --version | sed 's/git version //')
  pass "  Git version $GIT_VER"
fi

# -----------------------------------------------------------
# Summary
# -----------------------------------------------------------
echo ""
echo "==========================================="
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "==========================================="
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "❌ Environment is NOT ready. Fix the failures above before the demo."
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "⚠️  Environment is mostly ready but has warnings. Review above."
  exit 0
else
  echo "✅ Environment is ready for the demo!"
  exit 0
fi
