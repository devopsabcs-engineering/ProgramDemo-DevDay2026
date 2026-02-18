#!/usr/bin/env bash
set -euo pipefail

echo "=== OPS Program Demo - DevDay 2026 ==="
echo "Setting up development environment..."

# -------------------------------------------------------
# 1. Install SQL Server command-line tools (sqlcmd, bcp)
# -------------------------------------------------------
echo "Installing Microsoft SQL tools..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" | sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null
sudo apt-get update -qq
sudo ACCEPT_EULA=Y apt-get install -y -qq mssql-tools18 unixodbc-dev 2>/dev/null
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> "$HOME/.bashrc"
export PATH="$PATH:/opt/mssql-tools18/bin"

# -------------------------------------------------------
# 2. Install Flyway CLI for database migrations
# -------------------------------------------------------
echo "Installing Flyway CLI..."
FLYWAY_VERSION="10.10.0"
curl -fsSL "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz" | sudo tar -xz -C /opt
sudo ln -sf "/opt/flyway-${FLYWAY_VERSION}/flyway" /usr/local/bin/flyway

# -------------------------------------------------------
# 3. Install Azure Bicep CLI
# -------------------------------------------------------
echo "Installing Bicep CLI..."
az bicep install 2>/dev/null || true

# -------------------------------------------------------
# 4. Pre-install backend dependencies (if pom.xml exists)
# -------------------------------------------------------
if [ -f "backend/pom.xml" ]; then
  echo "Pre-downloading Maven dependencies..."
  cd backend
  mvn dependency:go-offline -q 2>/dev/null || true
  cd ..
fi

# -------------------------------------------------------
# 5. Pre-install frontend dependencies (if package.json exists)
# -------------------------------------------------------
if [ -f "frontend/package.json" ]; then
  echo "Pre-installing npm dependencies..."
  cd frontend
  npm ci --prefer-offline 2>/dev/null || npm install 2>/dev/null || true
  cd ..
fi

# -------------------------------------------------------
# 6. Verify installed tools
# -------------------------------------------------------
echo ""
echo "=== Environment Ready ==="
echo "Java:    $(java --version 2>&1 | head -1)"
echo "Maven:   $(mvn --version 2>&1 | head -1)"
echo "Node:    $(node --version)"
echo "npm:     $(npm --version)"
echo "Azure:   $(az version --output tsv 2>/dev/null | head -1 || echo 'installed')"
echo "GitHub:  $(gh --version 2>&1 | head -1)"
echo "sqlcmd:  $(sqlcmd --version 2>/dev/null | head -1 || echo 'installed')"
echo "Flyway:  $(flyway --version 2>/dev/null | head -1 || echo 'installed')"
echo "Bicep:   $(az bicep version 2>/dev/null || echo 'installed')"
echo ""
echo "Ports: 8080 (Backend API), 5173 (Frontend Vite)"
echo "=== Happy demo day! ==="
