# ============================================================
# verify-env.ps1 — Verify all demo dependencies are installed
# Run this before the demo to confirm the environment is ready.
# Usage: pwsh .devcontainer/verify-env.ps1
# ============================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Pass = 0
$script:Fail = 0
$script:Warn = 0

function Write-Pass {
    param([string]$Message)
    Write-Host "  ✅ $Message"
    $script:Pass++
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  ❌ $Message"
    $script:Fail++
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  ⚠️  $Message"
    $script:Warn++
}

function Test-Command {
    param(
        [string]$Command,
        [string]$Label
    )
    if (-not $Label) { $Label = $Command }
    $found = Get-Command $Command -ErrorAction SilentlyContinue
    if ($found) {
        return $true
    }
    else {
        Write-Fail "$Label not found"
        return $false
    }
}

function Test-Version {
    param(
        [string]$Actual,
        [string]$Expected,
        [string]$Label
    )
    if ($Actual.StartsWith($Expected)) {
        Write-Pass "$Label $Actual"
    }
    else {
        Write-Fail "$Label expected $Expected.x, got $Actual"
    }
}

Write-Host ""
Write-Host "=== OPS Program Demo — Environment Verification ==="
Write-Host ""

# -----------------------------------------------------------
# Java 21
# -----------------------------------------------------------
Write-Host "Java:"
if (Test-Command 'java' 'Java') {
    $javaOut = & java -version 2>&1 | Select-Object -First 1
    if ($javaOut -match '"(.+?)"') {
        $javaVer = $Matches[1]
    }
    else {
        $javaVer = ($javaOut -replace '[^0-9.]', '').Trim()
    }
    Test-Version $javaVer '21' '  JDK version'
}

# -----------------------------------------------------------
# Maven 3.x
# -----------------------------------------------------------
Write-Host "Maven:"
if (Test-Command 'mvn' 'Maven') {
    $mvnOut = & mvn --version 2>&1 | Select-Object -First 1
    if ($mvnOut -match 'Apache Maven ([^\s]+)') {
        $mvnVer = $Matches[1]
    }
    else {
        $mvnVer = 'unknown'
    }
    if ($mvnVer.StartsWith('3.')) {
        Write-Pass "  Maven version $mvnVer"
    }
    else {
        Write-Warn "  Maven version $mvnVer (expected 3.x)"
    }
}

# -----------------------------------------------------------
# Node.js 20.x
# -----------------------------------------------------------
Write-Host "Node.js:"
if (Test-Command 'node' 'Node.js') {
    $nodeVer = (& node --version).TrimStart('v')
    Test-Version $nodeVer '20' '  Node.js version'
}

# -----------------------------------------------------------
# npm
# -----------------------------------------------------------
Write-Host "npm:"
if (Test-Command 'npm' 'npm') {
    $npmVer = & npm --version 2>&1
    Write-Pass "  npm version $npmVer"
}

# -----------------------------------------------------------
# Azure CLI
# -----------------------------------------------------------
Write-Host "Azure CLI:"
if (Test-Command 'az' 'Azure CLI') {
    try {
        $azJson = & az version --output json 2>$null | ConvertFrom-Json
        $azVer = $azJson.'azure-cli'
    }
    catch {
        $azVer = 'unknown'
    }
    Write-Pass "  Azure CLI version $azVer"
}

# -----------------------------------------------------------
# GitHub CLI
# -----------------------------------------------------------
Write-Host "GitHub CLI:"
if (Test-Command 'gh' 'GitHub CLI') {
    $ghOut = & gh --version 2>&1 | Select-Object -First 1
    if ($ghOut -match 'gh version ([^\s]+)') {
        $ghVer = $Matches[1]
    }
    else {
        $ghVer = 'unknown'
    }
    Write-Pass "  GitHub CLI version $ghVer"
}

# -----------------------------------------------------------
# .NET SDK 8.x (for Azure Functions)
# -----------------------------------------------------------
Write-Host ".NET SDK:"
if (Test-Command 'dotnet' '.NET SDK') {
    $dotnetVer = & dotnet --version 2>$null
    Test-Version $dotnetVer '8' '  .NET SDK version'
}

# -----------------------------------------------------------
# SQL Server tools (sqlcmd)
# -----------------------------------------------------------
Write-Host "SQL Server tools:"
$sqlcmdFound = $false
if (Get-Command 'sqlcmd' -ErrorAction SilentlyContinue) {
    $sqlcmdOut = & sqlcmd -? 2>&1 | Select-Object -First 1
    Write-Pass "  sqlcmd $sqlcmdOut"
    $sqlcmdFound = $true
}

if (-not $sqlcmdFound) {
    # Check common Windows install paths
    $sqlcmdPaths = @(
        "$env:ProgramFiles\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn\sqlcmd.exe",
        "$env:ProgramFiles\Microsoft SQL Server\*\Tools\Binn\sqlcmd.exe"
    )
    foreach ($pattern in $sqlcmdPaths) {
        $resolved = Resolve-Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved) {
            $sqlcmdOut = & $resolved.Path -? 2>&1 | Select-Object -First 1
            Write-Pass "  sqlcmd $sqlcmdOut (at $($resolved.Path))"
            Write-Warn "  sqlcmd not on PATH — add its directory to PATH"
            $sqlcmdFound = $true
            break
        }
    }
}

if (-not $sqlcmdFound) {
    Write-Fail "sqlcmd not found"
}

# -----------------------------------------------------------
# Flyway CLI
# -----------------------------------------------------------
Write-Host "Flyway:"
if (Test-Command 'flyway' 'Flyway CLI') {
    $flywayOut = & flyway --version 2>$null
    if ($flywayOut -match '[\d.]+') {
        $flywayVer = $Matches[0]
    }
    else {
        $flywayVer = 'installed'
    }
    Write-Pass "  Flyway version $flywayVer"
}

# -----------------------------------------------------------
# Bicep CLI (via az bicep)
# -----------------------------------------------------------
Write-Host "Bicep:"
if (Get-Command 'az' -ErrorAction SilentlyContinue) {
    try {
        $bicepOut = & az bicep version 2>$null
        if ($bicepOut -match '[\d.]+') {
            $bicepVer = $Matches[0]
            Write-Pass "  Bicep CLI version $bicepVer"
        }
        else {
            Write-Warn "  Bicep CLI not installed — run 'az bicep install'"
        }
    }
    catch {
        Write-Warn "  Bicep CLI not installed — run 'az bicep install'"
    }
}
else {
    Write-Fail "Bicep CLI requires Azure CLI"
}

# -----------------------------------------------------------
# Git
# -----------------------------------------------------------
Write-Host "Git:"
if (Test-Command 'git' 'Git') {
    $gitOut = & git --version
    $gitVer = $gitOut -replace 'git version ', ''
    Write-Pass "  Git version $gitVer"
}

# -----------------------------------------------------------
# Summary
# -----------------------------------------------------------
Write-Host ""
Write-Host "==========================================="
Write-Host "  Results: $script:Pass passed, $script:Fail failed, $script:Warn warnings"
Write-Host "==========================================="
Write-Host ""

if ($script:Fail -gt 0) {
    Write-Host "❌ Environment is NOT ready. Fix the failures above before the demo."
    exit 1
}
elseif ($script:Warn -gt 0) {
    Write-Host "⚠️  Environment is mostly ready but has warnings. Review above."
    exit 0
}
else {
    Write-Host "✅ Environment is ready for the demo!"
    exit 0
}
