<#
.SYNOPSIS
    Starts the Azure Functions project locally with Azurite storage emulator.

.DESCRIPTION
    Ensures Azurite (local Azure Storage emulator) is running, then starts the
    PdfSummarizer Azure Functions project using 'func start'.

    Prerequisites:
      - Node.js (npm) installed.
      - Azure Functions Core Tools v4 installed (func).
      - .NET 8 SDK installed.

    The script will:
      1. Check that required tools are available.
      2. Install Azurite globally via npm if not already installed.
      3. Start Azurite as a background process (blob, queue, table on default ports).
      4. Build and start the Functions project with 'func start'.
      5. Stop Azurite when the Functions host is terminated (Ctrl+C).

.PARAMETER SkipBuild
    Skip the dotnet build step (use existing output).

.PARAMETER AzuritePort
    Override the base port for Azurite blob service (default: 10000).
    Queue = AzuritePort + 1, Table = AzuritePort + 2.

.EXAMPLE
    .\Start-Functions-Local.ps1
    # Build and start Functions with Azurite on default ports.

.EXAMPLE
    .\Start-Functions-Local.ps1 -SkipBuild
    # Start without rebuilding (faster iteration).
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [int]$AzuritePort = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Configuration ---
$RootDir       = Split-Path -Parent $PSScriptRoot
$FunctionsDir  = Join-Path $RootDir 'functions' 'PdfSummarizer'
$BlobPort      = $AzuritePort
$QueuePort     = $AzuritePort + 1
$TablePort     = $AzuritePort + 2
$AzuriteDataDir = Join-Path $RootDir '.azurite'

# --- Helper: Check for required tools ---
function Assert-ToolAvailable {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: '$Name' is not installed or not in PATH." -ForegroundColor Red
        Write-Host "  Install: $InstallHint" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`nOPS Program Demo - Azure Functions Local Runner`n" -ForegroundColor Cyan
Write-Host "Checking prerequisites..." -ForegroundColor Gray

Assert-ToolAvailable 'dotnet' 'https://dotnet.microsoft.com/download'
Assert-ToolAvailable 'func'   'npm install -g azure-functions-core-tools@4 --unsafe-perm true'
Assert-ToolAvailable 'npm'    'https://nodejs.org/'

# --- Install or upgrade Azurite if needed ---
$azuriteCmd = Get-Command 'azurite' -ErrorAction SilentlyContinue
if (-not $azuriteCmd) {
    Write-Host "Installing Azurite globally via npm..." -ForegroundColor Yellow
    npm install -g azurite@latest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to install Azurite." -ForegroundColor Red
        exit 1
    }
}
else {
    # Verify minimum version (3.30+) required for Azure SDK 2024-08-04 API
    $azuriteVersionLine = (npm list -g azurite --depth=0 2>$null) | Select-String 'azurite@(\d+)\.(\d+)'
    if ($azuriteVersionLine -and $azuriteVersionLine.Matches.Count -gt 0) {
        $major = [int]$azuriteVersionLine.Matches[0].Groups[1].Value
        $minor = [int]$azuriteVersionLine.Matches[0].Groups[2].Value
        if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 30)) {
            Write-Host "Azurite $major.$minor is too old. Upgrading..." -ForegroundColor Yellow
            npm install -g azurite@latest
        }
    }
}

# --- Check if Azurite is already running ---
$blobListening = Get-NetTCPConnection -LocalPort $BlobPort -State Listen -ErrorAction SilentlyContinue
if ($blobListening) {
    Write-Host "Azurite already running on port $BlobPort — skipping start." -ForegroundColor Gray
    $azuriteProcess = $null
}
else {
    # Create data directory if needed
    if (-not (Test-Path $AzuriteDataDir)) {
        New-Item -ItemType Directory -Path $AzuriteDataDir -Force | Out-Null
    }

    Write-Host "Starting Azurite (blob:$BlobPort, queue:$QueuePort, table:$TablePort)..." -ForegroundColor Green
    $azuriteProcess = Start-Process -FilePath 'azurite' `
        -ArgumentList "--silent --location `"$AzuriteDataDir`" --blobPort $BlobPort --queuePort $QueuePort --tablePort $TablePort" `
        -WindowStyle Hidden `
        -PassThru

    # Wait for Azurite to be ready
    $retries = 0
    $maxRetries = 15
    while ($retries -lt $maxRetries) {
        $listening = Get-NetTCPConnection -LocalPort $BlobPort -State Listen -ErrorAction SilentlyContinue
        if ($listening) {
            Write-Host "  Azurite is ready." -ForegroundColor Green
            break
        }
        Start-Sleep -Milliseconds 500
        $retries++
    }
    if ($retries -eq $maxRetries) {
        Write-Host "WARNING: Azurite may not have started. Continuing anyway..." -ForegroundColor Yellow
    }
}

# --- Stop any previous Functions host that may lock DLLs ---
$staleHosts = Get-Process -Name 'func' -ErrorAction SilentlyContinue
if (-not $staleHosts) {
    # func host runs as dotnet; find processes with the output path in their command line
    $staleHosts = Get-Process -Name 'dotnet' -ErrorAction SilentlyContinue |
        Where-Object {
            try { $_.MainModule.FileName -and $_.CommandLine -like '*PdfSummarizer*' } catch { $false }
        }
}
if ($staleHosts) {
    Write-Host "Stopping previous Functions host process(es)..." -ForegroundColor Yellow
    $staleHosts | ForEach-Object {
        Write-Host "  Killing PID $($_.Id) ($($_.ProcessName))" -ForegroundColor Yellow
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
}

# --- Build Functions project ---
if (-not $SkipBuild) {
    Write-Host "`nBuilding Functions project..." -ForegroundColor Green
    Push-Location $FunctionsDir
    try {
        dotnet build --configuration Debug
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: dotnet build failed." -ForegroundColor Red
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "`nSkipping build (using existing output)." -ForegroundColor Gray
}

# --- Start Functions host ---
Write-Host "`nStarting Azure Functions host..." -ForegroundColor Green
Write-Host "  Project: $FunctionsDir" -ForegroundColor Gray
Write-Host "  Press Ctrl+C to stop.`n" -ForegroundColor Gray

Push-Location $FunctionsDir
try {
    func start
}
finally {
    Pop-Location

    # Clean up Azurite
    if ($azuriteProcess -and -not $azuriteProcess.HasExited) {
        Write-Host "`nStopping Azurite (PID: $($azuriteProcess.Id))..." -ForegroundColor Yellow
        Stop-Process -Id $azuriteProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Host "  Azurite stopped." -ForegroundColor Green
    }
}

Write-Host "`nFunctions host stopped.`n" -ForegroundColor Cyan
