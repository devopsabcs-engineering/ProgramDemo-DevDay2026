<#
.SYNOPSIS
    Stops all local services for the OPS Program Approval Demo.

.DESCRIPTION
    Stops the backend (Java/Spring Boot) and frontend (Node/Vite) processes
    running on their default ports.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BackendPort = 8080
$FrontendPort = 3000
$JarName = 'program-demo-0.4.0-SNAPSHOT.jar'

Write-Host "`nStopping OPS Program Approval Demo services...`n" -ForegroundColor Cyan

# Stop processes on backend port
$backendConns = Get-NetTCPConnection -LocalPort $BackendPort -State Listen -ErrorAction SilentlyContinue
if ($backendConns) {
    foreach ($conn in $backendConns) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "  Stopping $($proc.ProcessName) (PID: $($proc.Id)) on port $BackendPort" -ForegroundColor Red
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
else {
    Write-Host "  No process found on port $BackendPort (backend)." -ForegroundColor Gray
}

# Stop processes on frontend port
$frontendConns = Get-NetTCPConnection -LocalPort $FrontendPort -State Listen -ErrorAction SilentlyContinue
if ($frontendConns) {
    foreach ($conn in $frontendConns) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "  Stopping $($proc.ProcessName) (PID: $($proc.Id)) on port $FrontendPort" -ForegroundColor Red
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
else {
    Write-Host "  No process found on port $FrontendPort (frontend)." -ForegroundColor Gray
}

# Stop any orphaned java processes running the demo JAR
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

Write-Host "`nAll services stopped.`n" -ForegroundColor Green
