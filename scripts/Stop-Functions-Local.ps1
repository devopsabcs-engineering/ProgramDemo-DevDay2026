<#
.SYNOPSIS
    Stops the local Azure Functions host and Azurite storage emulator.

.DESCRIPTION
    Stops any running Azure Functions host (func) and Azurite processes,
    and releases the default ports (7071, 10000-10002).
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$FuncPort    = 7071
$BlobPort    = 10000
$QueuePort   = 10001
$TablePort   = 10002

Write-Host "`nStopping Azure Functions local services...`n" -ForegroundColor Cyan

# Stop Functions host
$funcConns = Get-NetTCPConnection -LocalPort $FuncPort -State Listen -ErrorAction SilentlyContinue
if ($funcConns) {
    foreach ($conn in $funcConns) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "  Stopping $($proc.ProcessName) (PID: $($proc.Id)) on port $FuncPort" -ForegroundColor Red
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
else {
    Write-Host "  No Functions host found on port $FuncPort." -ForegroundColor Gray
}

# Stop Azurite
foreach ($port in @($BlobPort, $QueuePort, $TablePort)) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conns) {
        foreach ($conn in $conns) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "  Stopping $($proc.ProcessName) (PID: $($proc.Id)) on port $port" -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Also stop any lingering Azurite/node processes by name
$azuriteProcs = Get-Process -Name 'azurite' -ErrorAction SilentlyContinue
if ($azuriteProcs) {
    foreach ($proc in $azuriteProcs) {
        Write-Host "  Stopping azurite (PID: $($proc.Id))" -ForegroundColor Red
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`nAll local Functions services stopped.`n" -ForegroundColor Green
