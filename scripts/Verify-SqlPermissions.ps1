<#
.SYNOPSIS
    Verifies and fixes the SQL AAD admin configuration for the OPS Program Demo.

.DESCRIPTION
    The SQL Server uses a user-assigned managed identity (id-sql-admin-*) as its
    AAD administrator. The App Service runs as that same identity, so no separate
    SQL user provisioning is required.

    This script checks and fixes:
    1. SQL Server AAD admin is configured.
    2. Admin sid == MI principalId (Object ID).  The most common misconfiguration
       is that the sid was set to the clientId instead.  SQL Server compares the
       sid against the oid claim in the AAD token — they must match.
    3. MI has Directory Readers role in Entra ID (needed to resolve external
       provider names during CREATE USER FROM EXTERNAL PROVIDER).
    4. Backend App Service has the user-assigned MI attached.
    5. SQL connectivity smoke-test using the caller's own AAD token (works only
       when run from a machine with network access to the SQL private endpoint).

    The script is idempotent — it only fixes what is wrong.

.PARAMETER Environment
    Target environment (dev, test, prod). Default: dev

.PARAMETER InstanceNumber
    Instance number for resource naming. Default: 123

.PARAMETER Prefix
    Resource naming prefix. Default: ops-demo

.PARAMETER FixIssues
    When set, automatically fixes any issues found. Without this flag,
    the script only reports.

.EXAMPLE
    .\Verify-SqlPermissions.ps1
    .\Verify-SqlPermissions.ps1 -FixIssues
    .\Verify-SqlPermissions.ps1 -Environment dev -InstanceNumber 123 -FixIssues
#>

[CmdletBinding()]
param(
    [ValidateSet('dev', 'test', 'prod')]
    [string]$Environment = 'dev',

    [string]$InstanceNumber = '123',

    [string]$Prefix = 'ops-demo',

    [switch]$FixIssues
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail = '')
    $icon  = if ($Passed) { '[PASS]' } else { '[FAIL]' }
    $color = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host "$icon " -ForegroundColor $color -NoNewline
    Write-Host $Name -NoNewline
    if ($Detail) { Write-Host " — $Detail" } else { Write-Host '' }
}

function Write-Action {
    param([string]$Message)
    Write-Host '[FIX]  ' -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host '[INFO] ' -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host "═══ $Title " -ForegroundColor White
    Write-Host ('═' * 70) -ForegroundColor DarkGray
}

# ── Counters ─────────────────────────────────────────────────────────────────

$totalChecks  = 0
$passedChecks = 0
$fixedChecks  = 0
$failedChecks = 0

function Add-CheckResult {
    param([bool]$Passed, [bool]$Fixed = $false)
    $script:totalChecks++
    if ($Passed)    { $script:passedChecks++ }
    elseif ($Fixed) { $script:fixedChecks++  }
    else            { $script:failedChecks++ }
}

# ── Derived Names ────────────────────────────────────────────────────────────

$resourceGroup      = "rg-$Environment-$InstanceNumber"
$sqlServerName      = "sql-$Prefix-$Environment-$InstanceNumber"
$backendAppName     = "app-$Prefix-api-$Environment-$InstanceNumber"
$sqlAdminMiName     = "id-sql-admin-$Prefix-$Environment-$InstanceNumber"
$databaseName       = 'programdb'
$directoryReadersId = '88d8e3e3-8f55-4a1e-953a-9b9898b8876b'

# ── Preflight ────────────────────────────────────────────────────────────────

Write-Section 'Preflight'

try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Info "Logged in as : $($account.user.name) ($($account.user.type))"
    Write-Info "Subscription : $($account.name) ($($account.id))"
} catch {
    Write-Error 'Not logged in to Azure CLI. Run: az login'
    exit 1
}

Write-Host @"

  Architecture
  ─────────────────────────────────────────────────────────────
  SQL Admin MI : $sqlAdminMiName
  SQL Server   : $sqlServerName
  Database     : $databaseName
  App Service  : $backendAppName
  ─────────────────────────────────────────────────────────────
  The App Service authenticates to SQL as the SQL admin MI.
  No separate database user provisioning is needed.

"@ -ForegroundColor Gray

# ── 1. Managed Identity ──────────────────────────────────────────────────────

Write-Section '1. SQL Admin Managed Identity'

$miPrincipalId = $null
$miClientId    = $null
$miResourceId  = $null

try {
    $mi = az identity show `
        --name $sqlAdminMiName `
        --resource-group $resourceGroup `
        --only-show-errors 2>&1 | ConvertFrom-Json

    $miPrincipalId = $mi.principalId
    $miClientId    = $mi.clientId
    $miResourceId  = $mi.id

    Write-Check "MI exists: $sqlAdminMiName" $true
    Write-Info  "  principalId (Object ID) : $miPrincipalId"
    Write-Info  "  clientId (App ID)       : $miClientId"
    Add-CheckResult $true
} catch {
    Write-Check "MI exists: $sqlAdminMiName" $false $_.Exception.Message
    Add-CheckResult $false
    Write-Error "Managed identity not found. Deploy infrastructure first: gh workflow run deploy-infra.yml"
    exit 1
}

# ── 2. SQL Server AAD Admin SID ──────────────────────────────────────────────

Write-Section '2. SQL Server AAD Admin Configuration'

try {
    az sql server show `
        --name $sqlServerName `
        --resource-group $resourceGroup `
        --only-show-errors 2>&1 | Out-Null
    Write-Check "SQL Server exists: $sqlServerName" $true
    Add-CheckResult $true
} catch {
    Write-Check "SQL Server exists: $sqlServerName" $false $_.Exception.Message
    Add-CheckResult $false
    Write-Error "SQL Server not found. Deploy infrastructure first."
    exit 1
}

$adminSid    = $null
$adminLogin  = $null
$aadOnlyAuth = $false

try {
    $sqlAdmins = az sql server ad-admin list `
        --server-name $sqlServerName `
        --resource-group $resourceGroup `
        --only-show-errors 2>&1 | ConvertFrom-Json

    if ($sqlAdmins -and $sqlAdmins.Count -gt 0) {
        $adminEntry  = $sqlAdmins[0]
        $adminLogin  = $adminEntry.login
        $adminSid    = $adminEntry.sid
        $aadOnlyAuth = [bool]$adminEntry.azureAdOnlyAuthentication

        Write-Check 'AAD admin is configured' $true $adminLogin
        Write-Info  "  sid in SQL : $adminSid"
        Write-Info  "  Expected   : $miPrincipalId  (MI principalId / Object ID)"
        Add-CheckResult $true
    } else {
        Write-Check 'AAD admin is configured' $false 'No AAD admin set on SQL Server'
        Add-CheckResult $false
        Write-Host ''
        Write-Host 'Fix: redeploy infrastructure — sql.bicep sets the AAD admin block.' -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Check 'Read SQL AAD admin' $false $_.Exception.Message
    Add-CheckResult $false
    exit 1
}

# KEY CHECK: sid must equal the MI principalId (Object ID).
# SQL Server stores the sid set at creation time and compares it against the
# oid claim in the incoming AAD token.  A common bug is setting sid to the
# clientId (Application ID) instead — both are GUIDs so it looks plausible
# but authentication always fails with "SQL Server did not return a response".
if ($adminSid -eq $miPrincipalId) {
    Write-Check 'Admin sid == MI principalId' $true $miPrincipalId
    Add-CheckResult $true
} else {
    Write-Check 'Admin sid == MI principalId' $false `
        "sid=$adminSid  ≠  principalId=$miPrincipalId"
    Write-Info '  Root cause of FedAuth failure:'
    Write-Info '  SQL Server validates the token oid claim against the stored sid.'
    Write-Info '  Using clientId as sid causes auth to fail at the FedAuth handshake.'
    if ($FixIssues) {
        Write-Action "Updating SQL AAD admin sid to principalId=$miPrincipalId ..."
        az sql server ad-admin update `
            --server-name $sqlServerName `
            --resource-group $resourceGroup `
            --object-id $miPrincipalId `
            --display-name $sqlAdminMiName `
            --only-show-errors 2>&1 | Out-Null
        Write-Check 'Admin sid updated to principalId' $true '(fixed)'
        Add-CheckResult $false $true

        Write-Info ''
        Write-Info 'Restarting App Service to re-establish connections with corrected SID...'
        az webapp restart `
            --name $backendAppName `
            --resource-group $resourceGroup `
            --only-show-errors 2>&1 | Out-Null
        Write-Check "App Service restarted: $backendAppName" $true
    } else {
        Write-Info ''
        Write-Info 'Run with -FixIssues to correct immediately (no redeploy needed):'
        Write-Info "  .\Verify-SqlPermissions.ps1 -FixIssues"
        Write-Info ''
        Write-Info 'Or correct manually:'
        Write-Info "  az sql server ad-admin update --server-name $sqlServerName --resource-group $resourceGroup --object-id $miPrincipalId --display-name $sqlAdminMiName"
        Write-Info "  az webapp restart --name $backendAppName --resource-group $resourceGroup"
        Add-CheckResult $false
    }
}

# AAD-only authentication
Write-Check 'AAD-only authentication enabled' $aadOnlyAuth
Add-CheckResult $aadOnlyAuth
if (-not $aadOnlyAuth) {
    Write-Info '  Password-based logins should be disabled. This is enforced in sql.bicep.'
}

# ── 3. Directory Readers Role ────────────────────────────────────────────────

Write-Section '3. Directory Readers Role on SQL Admin MI'

Write-Info 'Required: SQL Server resolves MI names via Entra ID during authentication.'
Write-Info "Checking MI: $sqlAdminMiName (principalId: $miPrincipalId)"

function Test-DirectoryReadersRole {
    param([string]$PrincipalId)
    try {
        $filterParam = "roleDefinitionId eq '$directoryReadersId' and principalId eq '$PrincipalId'"
        $graphUrl    = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?`$filter=$filterParam"
        $raw         = az rest --method GET --url $graphUrl --only-show-errors 2>&1
        $rawStr      = ($raw | Out-String).Trim()
        if ($rawStr -match 'ERROR') { return $null }
        $parsed      = $rawStr | ConvertFrom-Json
        return ($parsed.value -and $parsed.value.Count -gt 0)
    } catch {
        return $null
    }
}

function Grant-DirectoryReadersRole {
    param([string]$PrincipalId)
    $body = @{
        '@odata.type'    = '#microsoft.graph.unifiedRoleAssignment'
        roleDefinitionId = $directoryReadersId
        principalId      = $PrincipalId
        directoryScopeId = '/'
    } | ConvertTo-Json -Compress

    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tempFile -Value $body -Encoding UTF8 -NoNewline
        $result = az rest --method POST `
            --url 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments' `
            --headers 'Content-Type=application/json' `
            --body "@$tempFile" `
            --only-show-errors 2>&1
        $resultStr = ($result | Out-String).Trim()
        return if ($resultStr -match 'ERROR') { $resultStr } else { $null }
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

$hasDirectoryReaders = Test-DirectoryReadersRole -PrincipalId $miPrincipalId

if ($hasDirectoryReaders -eq $true) {
    Write-Check 'SQL admin MI has Directory Readers role' $true
    Add-CheckResult $true
} elseif ($hasDirectoryReaders -eq $false) {
    Write-Check 'SQL admin MI has Directory Readers role' $false 'Missing'
    if ($FixIssues) {
        Write-Action "Assigning Directory Readers to $sqlAdminMiName ..."
        $err = Grant-DirectoryReadersRole -PrincipalId $miPrincipalId
        if (-not $err) {
            Write-Check 'Directory Readers role assigned' $true '(fixed)'
            Add-CheckResult $false $true
        } else {
            Write-Check 'Directory Readers role assignment' $false $err
            Add-CheckResult $false
        }
    } else {
        Write-Info 'Run with -FixIssues to assign automatically.'
        Write-Info "Or assign manually in Entra ID > Roles > Directory Readers > Assignments."
        Add-CheckResult $false
    }
} else {
    Write-Check 'Directory Readers role check' $false 'Graph API error — check permissions'
    Write-Info '  Your account may lack permission to read role assignments.'
    Write-Info '  Verify manually: Entra ID > Roles and administrators > Directory Readers.'
    Add-CheckResult $false
}

# ── 4. App Service Identity ──────────────────────────────────────────────────

Write-Section '4. Backend App Service — User-Assigned MI'

Write-Info "App Service : $backendAppName"
Write-Info "Expected MI : $sqlAdminMiName  ($miPrincipalId)"

try {
    $identityJson = az webapp show `
        --name $backendAppName `
        --resource-group $resourceGroup `
        --query 'identity' `
        --only-show-errors 2>&1 | ConvertFrom-Json

    $identityType = $identityJson.type
    Write-Info "Identity type : $identityType"

    # Check the specific user-assigned MI is attached
    $uamiAttached = $false
    if ($identityJson.userAssignedIdentities) {
        $count = $identityJson.userAssignedIdentities.PSObject.Properties |
            Where-Object { $_.Value.principalId -eq $miPrincipalId } |
            Measure-Object | Select-Object -ExpandProperty Count
        $uamiAttached = ($count -gt 0)
    }

    Write-Check "User-assigned MI attached: $sqlAdminMiName" $uamiAttached
    Add-CheckResult $uamiAttached

    if (-not $uamiAttached) {
        if ($FixIssues) {
            Write-Action "Attaching MI $sqlAdminMiName to $backendAppName ..."
            az webapp identity assign `
                --name $backendAppName `
                --resource-group $resourceGroup `
                --identities $miResourceId `
                --only-show-errors 2>&1 | Out-Null
            Write-Check 'User-assigned MI attached' $true '(fixed — restart the app to take effect)'
            Add-CheckResult $false $true

            Write-Action "Restarting App Service ..."
            az webapp restart `
                --name $backendAppName `
                --resource-group $resourceGroup `
                --only-show-errors 2>&1 | Out-Null
            Write-Check "App Service restarted: $backendAppName" $true
        } else {
            Write-Info 'Run with -FixIssues to attach the MI, or redeploy via deploy-infra workflow.'
            Add-CheckResult $false
        }
    }

    # Verify SPRING_DATASOURCE_URL contains msiClientId
    $dsUrl = az webapp config appsettings list `
        --name $backendAppName `
        --resource-group $resourceGroup `
        --only-show-errors 2>&1 | ConvertFrom-Json |
        Where-Object { $_.name -eq 'SPRING_DATASOURCE_URL' } |
        Select-Object -ExpandProperty value

    if ($dsUrl) {
        Write-Info "SPRING_DATASOURCE_URL: $dsUrl"
        $hasMsiClientId = $dsUrl -match 'msiClientId='
        Write-Check 'JDBC URL contains msiClientId' $hasMsiClientId
        Add-CheckResult $hasMsiClientId

        if ($hasMsiClientId) {
            $urlHasCorrectClientId = $dsUrl -match [regex]::Escape($miClientId)
            Write-Check "msiClientId == MI clientId ($miClientId)" $urlHasCorrectClientId
            Add-CheckResult $urlHasCorrectClientId
            if (-not $urlHasCorrectClientId) {
                Write-Info '  The msiClientId in the JDBC URL does not match the MI clientId.'
                Write-Info '  Redeploy via deploy-infra workflow to update the App Setting.'
            }
        } else {
            Write-Info '  msiClientId not in JDBC URL. Without it the MSSQL driver uses the'
            Write-Info '  system-assigned MI (if any) instead of the user-assigned admin MI.'
            Write-Info '  Redeploy via deploy-infra workflow to update the App Setting.'
            Add-CheckResult $false
        }
    } else {
        Write-Check 'SPRING_DATASOURCE_URL App Setting found' $false
        Add-CheckResult $false
    }

} catch {
    Write-Check "App Service reachable: $backendAppName" $false $_.Exception.Message
    Add-CheckResult $false
}

# ── 5. SQL Connectivity Smoke Test ───────────────────────────────────────────

Write-Section '5. SQL Connectivity Smoke Test'

Write-Info 'Uses the current Azure CLI identity (your own account, not the MI).'
Write-Info "SQL: $sqlServerName.database.windows.net / $databaseName"
Write-Info 'NOTE: SQL is private-endpoint-only. This test succeeds only when run'
Write-Info 'from inside the VNet or a machine with a route to the private endpoint.'
Write-Host ''

$sqlModuleAvailable = $null -ne (Get-Module -ListAvailable -Name SqlServer -ErrorAction SilentlyContinue)

if (-not $sqlModuleAvailable) {
    Write-Info 'SqlServer PowerShell module not installed — skipping connectivity test.'
    Write-Info 'To install: Install-Module SqlServer -Scope CurrentUser'
} else {
    try {
        $token = az account get-access-token `
            --resource 'https://database.windows.net/' `
            --query 'accessToken' -o tsv 2>&1

        if (-not $token -or $token -match 'ERROR') {
            throw "Could not obtain SQL access token: $token"
        }

        $result = Invoke-Sqlcmd `
            -ServerInstance "$sqlServerName.database.windows.net" `
            -Database $databaseName `
            -AccessToken $token `
            -Query 'SELECT SYSTEM_USER AS [Identity], USER_NAME() AS [DbUser];' `
            -ErrorAction Stop `
            -TrustServerCertificate

        Write-Check 'SQL connectivity (as current user)' $true
        Write-Info  "  SQL identity : $($result.Identity)"
        Write-Info  "  DB user      : $($result.DbUser)"
        Add-CheckResult $true
    } catch {
        $msg = $_.Exception.Message
        if ($msg -match 'No such host|connection|network|timeout|A network-related') {
            Write-Check 'SQL connectivity' $false 'Network unreachable (expected from outside VNet)'
        } else {
            Write-Check 'SQL connectivity' $false $msg
        }
        Add-CheckResult $false
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Section 'Summary'

Write-Host "  Total checks : $totalChecks"
Write-Host "  Passed       : $passedChecks" -ForegroundColor Green
if ($fixedChecks -gt 0) {
    Write-Host "  Fixed        : $fixedChecks" -ForegroundColor Yellow
}
if ($failedChecks -gt 0) {
    Write-Host "  Failed       : $failedChecks" -ForegroundColor Red
}

Write-Host ''

if ($failedChecks -eq 0 -and $fixedChecks -eq 0) {
    Write-Host 'All checks passed. Configuration is correct.' -ForegroundColor Green
    exit 0
} elseif ($failedChecks -eq 0) {
    Write-Host "Fixed $fixedChecks issue(s). Monitor the App Service for recovery." -ForegroundColor Yellow
    exit 0
} else {
    if (-not $FixIssues) {
        Write-Host "$failedChecks check(s) failed. Run with -FixIssues to fix automatically:" -ForegroundColor Red
        Write-Host "  .\Verify-SqlPermissions.ps1 -FixIssues" -ForegroundColor Yellow
    } else {
        Write-Host "$failedChecks check(s) could not be fixed automatically. Review output above." -ForegroundColor Red
    }
    exit 1
}
