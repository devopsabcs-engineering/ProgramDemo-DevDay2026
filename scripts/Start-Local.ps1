<#
.SYNOPSIS
    Starts all local services for the OPS Program Approval Demo.

.DESCRIPTION
    Stops existing backend/frontend processes, rebuilds the backend and frontend,
    then starts both services for local development and testing.

    Backend: Spring Boot on http://localhost:8080
    Frontend: Vite dev server on http://localhost:3000 (proxies /api to backend)

.PARAMETER SkipBuild
    Skip the Maven and npm build steps (use existing artifacts).

.PARAMETER BackendOnly
    Start only the backend service.

.PARAMETER FrontendOnly
    Start only the frontend service.

.EXAMPLE
    .\Start-Local.ps1
    # Full rebuild and start of all services.

.EXAMPLE
    .\Start-Local.ps1 -SkipBuild
    # Start services without rebuilding.

.EXAMPLE
    .\Start-Local.ps1 -BackendOnly
    # Rebuild and start only the backend.
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$BackendOnly,
    [switch]$FrontendOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Configuration ---
$RootDir = Split-Path -Parent $PSScriptRoot
$BackendDir = Join-Path $RootDir 'backend'
$FrontendDir = Join-Path $RootDir 'frontend'
$JarName = 'program-demo-0.4.0-SNAPSHOT.jar'
$JarPath = Join-Path $BackendDir "target/$JarName"
$BackendPort = 8080
$FrontendPort = 3000
$HealthCheckUrl = "http://localhost:$BackendPort/api/programs"
$HealthCheckTimeout = 60  # seconds

# --- Helper Functions ---

function Write-Step {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Stop-ProcessOnPort {
    param([int]$Port, [string]$ServiceName)

    Write-Host "Checking for processes on port $Port ($ServiceName)..." -ForegroundColor Yellow

    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($connections) {
        foreach ($conn in $connections) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "  Stopping $($proc.ProcessName) (PID: $($proc.Id)) on port $Port" -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        }
        Write-Host "  Cleared port $Port." -ForegroundColor Green
    }
    else {
        Write-Host "  Port $Port is free." -ForegroundColor Green
    }
}

function Wait-ForBackend {
    Write-Host "`nWaiting for backend to be ready..." -ForegroundColor Yellow
    $elapsed = 0
    $interval = 3

    while ($elapsed -lt $HealthCheckTimeout) {
        try {
            $response = Invoke-WebRequest -Uri $HealthCheckUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "  Backend is ready! (HTTP $($response.StatusCode))" -ForegroundColor Green
                return $true
            }
        }
        catch {
            # Not ready yet
        }
        Write-Host "  Waiting... ($elapsed/$HealthCheckTimeout seconds)" -ForegroundColor Gray
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }

    Write-Host "  WARNING: Backend did not respond within $HealthCheckTimeout seconds." -ForegroundColor Red
    Write-Host "  It may still be starting. Check the backend log window." -ForegroundColor Red
    return $false
}

# --- Main Script ---

Write-Host @"

  OPS Program Approval Demo - Local Development
  =============================================
  Backend:  http://localhost:$BackendPort
  Frontend: http://localhost:$FrontendPort
  API Proxy: /api -> http://localhost:$BackendPort

"@ -ForegroundColor White

# 1. Stop existing processes
Write-Step 'Stopping existing processes'

if (-not $FrontendOnly) {
    Stop-ProcessOnPort -Port $BackendPort -ServiceName 'Backend (Java)'
}
if (-not $BackendOnly) {
    Stop-ProcessOnPort -Port $FrontendPort -ServiceName 'Frontend (Vite/Node)'
}

# Also stop any orphaned java processes running the demo JAR
$javaProcs = Get-Process -Name 'java' -ErrorAction SilentlyContinue |
    Where-Object {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            $cmdLine -and $cmdLine -like "*$JarName*"
        }
        catch { $false }
    }

if ($javaProcs) {
    foreach ($proc in $javaProcs) {
        Write-Host "  Stopping orphaned Java process (PID: $($proc.Id))" -ForegroundColor Red
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

# 2. Build backend
if (-not $FrontendOnly) {
    if (-not $SkipBuild) {
        Write-Step 'Building Backend (Maven)'

        if (-not (Test-Path $BackendDir)) {
            Write-Error "Backend directory not found: $BackendDir"
        }

        Push-Location $BackendDir
        try {
            Write-Host "Running: mvn clean package -DskipTests" -ForegroundColor Gray
            & mvn clean package -DskipTests -q
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Maven build failed with exit code $LASTEXITCODE"
            }
            Write-Host "  Backend build successful." -ForegroundColor Green
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host "`nSkipping backend build (-SkipBuild)." -ForegroundColor Yellow
    }

    # Verify JAR exists
    if (-not (Test-Path $JarPath)) {
        Write-Error "Backend JAR not found: $JarPath. Run without -SkipBuild to build first."
    }
}

# 3. Build frontend
if (-not $BackendOnly) {
    if (-not $SkipBuild) {
        Write-Step 'Installing Frontend Dependencies'

        if (-not (Test-Path $FrontendDir)) {
            Write-Error "Frontend directory not found: $FrontendDir"
        }

        Push-Location $FrontendDir
        try {
            if (-not (Test-Path (Join-Path $FrontendDir 'node_modules'))) {
                Write-Host "Running: npm install" -ForegroundColor Gray
                & npm install
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "npm install failed with exit code $LASTEXITCODE"
                }
            }
            else {
                Write-Host "  node_modules exists, skipping npm install." -ForegroundColor Gray
            }
            Write-Host "  Frontend dependencies ready." -ForegroundColor Green
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host "`nSkipping frontend build (-SkipBuild)." -ForegroundColor Yellow
    }
}

# 4. Start backend
if (-not $FrontendOnly) {
    Write-Step 'Starting Backend'
    Write-Host "  JAR: $JarPath" -ForegroundColor Gray
    Write-Host "  Profile: local" -ForegroundColor Gray
    Write-Host "  URL: http://localhost:$BackendPort" -ForegroundColor Gray

    $backendProcess = Start-Process -FilePath 'java' `
        -ArgumentList "-jar `"$JarPath`" --spring.profiles.active=local" `
        -WorkingDirectory $BackendDir `
        -PassThru `
        -WindowStyle Normal

    Write-Host "  Backend started (PID: $($backendProcess.Id))" -ForegroundColor Green

    # Wait for backend to be ready before starting frontend
    if (-not $BackendOnly) {
        Wait-ForBackend | Out-Null
    }
    else {
        Wait-ForBackend | Out-Null
        Write-Host "`nBackend is running. Press Ctrl+C in the backend window to stop." -ForegroundColor White
    }
}

# 5. Start frontend
if (-not $BackendOnly) {
    Write-Step 'Starting Frontend'
    Write-Host "  URL: http://localhost:$FrontendPort" -ForegroundColor Gray

    $frontendProcess = Start-Process -FilePath 'npm' `
        -ArgumentList 'run dev' `
        -WorkingDirectory $FrontendDir `
        -PassThru `
        -WindowStyle Normal

    Write-Host "  Frontend started (PID: $($frontendProcess.Id))" -ForegroundColor Green
}

# 6. Summary
Write-Step 'All Services Started'

Write-Host @"

  Services Running:
  -----------------
$(if (-not $FrontendOnly) { "  Backend API:  http://localhost:$BackendPort/api/programs" })
$(if (-not $BackendOnly)  { "  Frontend UI:  http://localhost:$FrontendPort" })

  To stop all services, run:
    .\scripts\Stop-Local.ps1
    -- or --
    Close the backend and frontend terminal windows.

"@ -ForegroundColor White
