<#
.SYNOPSIS
    Verifies and grants all permissions required for the deploy-infra workflow
    to create SQL users via managed identity.

.DESCRIPTION
    This script checks and fixes:
    1. The SQL AAD admin group exists in Entra ID.
    2. The GitHub Actions service principal is a member of that group.
    3. The backend App Service managed identity exists.
    4. The SQL AAD admin group has the Directory Readers role (needed to
       resolve managed identity names during CREATE USER FROM EXTERNAL PROVIDER).
    5. The backend managed identity has the required SQL database roles
       (db_datareader, db_datawriter, db_ddladmin).

    The script is idempotent — it only adds missing permissions and reports
    what was already in place.

.PARAMETER Environment
    Target environment (dev, test, prod). Default: dev

.PARAMETER InstanceNumber
    Instance number for resource naming. Default: 123

.PARAMETER Prefix
    Resource naming prefix. Default: ops-demo

.PARAMETER ServicePrincipalAppId
    The Application (client) ID of the GitHub Actions service principal
    (AZURE_CLIENT_ID). If not provided, uses the current az login identity.

.PARAMETER SqlAdminGroupId
    The Object ID of the Entra ID group set as SQL AAD admin
    (SQL_AAD_ADMIN_OBJECT_ID). If not provided, reads from the SQL Server.

.PARAMETER FixIssues
    When set, automatically fixes any issues found. Without this flag,
    the script only reports.

.EXAMPLE
    .\Verify-SqlPermissions.ps1 -FixIssues
    .\Verify-SqlPermissions.ps1 -Environment dev -InstanceNumber 123 -FixIssues
    .\Verify-SqlPermissions.ps1 -ServicePrincipalAppId "aaaa-bbbb" -SqlAdminGroupId "cccc-dddd" -FixIssues
#>

[CmdletBinding()]
param(
    [ValidateSet('dev', 'test', 'prod')]
    [string]$Environment = 'dev',

    [string]$InstanceNumber = '123',

    [string]$Prefix = 'ops-demo',

    [string]$ServicePrincipalAppId,

    [string]$SqlAdminGroupId,

    [switch]$FixIssues
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail = '')
    $icon = if ($Passed) { '[PASS]' } else { '[FAIL]' }
    $color = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host "$icon " -ForegroundColor $color -NoNewline
    Write-Host "$Name" -NoNewline
    if ($Detail) { Write-Host " - $Detail" } else { Write-Host '' }
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
    Write-Host ('═' * 60) -ForegroundColor DarkGray
}

# ── Derived Names ────────────────────────────────────────────────────────────

$resourceGroup = "rg-$Environment-$InstanceNumber"
$sqlServerName = "sql-$Prefix-$Environment-$InstanceNumber"
$backendAppName = "app-$Prefix-api-$Environment-$InstanceNumber"
$databaseName = 'programdb'

$totalChecks = 0
$passedChecks = 0
$fixedChecks = 0
$failedChecks = 0

function Add-CheckResult {
    param([bool]$Passed, [bool]$Fixed = $false)
    $script:totalChecks++
    if ($Passed) { $script:passedChecks++ }
    elseif ($Fixed) { $script:fixedChecks++ }
    else { $script:failedChecks++ }
}

# ── Preflight ────────────────────────────────────────────────────────────────

Write-Section 'Preflight'

# Verify az CLI is logged in
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Info "Logged in as: $($account.user.name) (type: $($account.user.type))"
    Write-Info "Subscription: $($account.name) ($($account.id))"
} catch {
    Write-Error 'Not logged in to Azure CLI. Run: az login'
    exit 1
}

# If ServicePrincipalAppId not provided, try to derive from current login
if (-not $ServicePrincipalAppId) {
    if ($account.user.type -eq 'servicePrincipal') {
        $ServicePrincipalAppId = $account.user.name
        Write-Info "Using current service principal as target: $ServicePrincipalAppId"
    } else {
        Write-Info 'No -ServicePrincipalAppId provided and current login is not a service principal.'
        Write-Info 'Will skip service principal group membership check.'
    }
}

# ── 1. SQL Server & AAD Admin Group ─────────────────────────────────────────

Write-Section '1. SQL Server AAD Admin Configuration'

Write-Info "SQL Server: $sqlServerName (RG: $resourceGroup)"

try {
    $sqlServer = az sql server show `
        --name $sqlServerName `
        --resource-group $resourceGroup `
        --only-show-errors 2>&1 | ConvertFrom-Json

    Write-Check 'SQL Server exists' $true $sqlServerName
    Add-CheckResult $true
} catch {
    Write-Check 'SQL Server exists' $false "Cannot find $sqlServerName in $resourceGroup"
    Add-CheckResult $false
    Write-Error "SQL Server $sqlServerName not found. Deploy infrastructure first."
    exit 1
}

# Get the AAD admin configuration
$sqlAdmins = az sql server ad-admin list `
    --server-name $sqlServerName `
    --resource-group $resourceGroup `
    --only-show-errors 2>&1 | ConvertFrom-Json

if ($sqlAdmins -and $sqlAdmins.Count -gt 0) {
    $adminEntry = $sqlAdmins[0]
    $adminLogin = $adminEntry.login
    $adminSid = $adminEntry.sid
    $adminType = $adminEntry.administratorType

    Write-Check 'AAD Admin configured' $true "$adminLogin ($adminType)"
    Add-CheckResult $true

    if (-not $SqlAdminGroupId) {
        $SqlAdminGroupId = $adminSid
        Write-Info "Using SQL AAD admin SID as group ID: $SqlAdminGroupId"
    }
} else {
    Write-Check 'AAD Admin configured' $false 'No AAD admin set on SQL Server'
    Add-CheckResult $false
    Write-Error 'SQL Server has no AAD admin. Set one in sql.bicep and redeploy.'
    exit 1
}

# Check AAD-only auth
$aadOnly = $adminEntry.azureAdOnlyAuthentication
if ($null -eq $aadOnly) { $aadOnly = $false }
Write-Check 'AAD-only authentication enabled' ([bool]$aadOnly)
Add-CheckResult ([bool]$aadOnly)

# ── 2. Entra ID Group Validation ────────────────────────────────────────────

Write-Section '2. Entra ID Admin Group'

Write-Info "Admin Group Object ID: $SqlAdminGroupId"

try {
    $group = az ad group show --group $SqlAdminGroupId --only-show-errors 2>&1 | ConvertFrom-Json
    Write-Check 'Admin group exists in Entra ID' $true $group.displayName
    Add-CheckResult $true
} catch {
    Write-Check 'Admin group exists in Entra ID' $false "Group $SqlAdminGroupId not found"
    Add-CheckResult $false
    Write-Error "The AAD admin group ($SqlAdminGroupId) does not exist in Entra ID."
    exit 1
}

# List group members for reference
$members = az ad group member list --group $SqlAdminGroupId --only-show-errors 2>&1 | ConvertFrom-Json
Write-Info "Group members ($($members.Count)):"
foreach ($m in $members) {
    $mType = if ($m.'@odata.type' -match 'servicePrincipal') { 'SP' }
             elseif ($m.'@odata.type' -match 'user') { 'User' }
             elseif ($m.'@odata.type' -match 'group') { 'Group' }
             else { $m.'@odata.type' }
    Write-Info "  - [$mType] $($m.displayName) ($($m.id))"
}

# ── 3. Service Principal Group Membership ────────────────────────────────────

Write-Section '3. Service Principal Group Membership'

if ($ServicePrincipalAppId) {
    # Resolve the SP's object ID from its app (client) ID
    try {
        $spObjects = az ad sp list --filter "appId eq '$ServicePrincipalAppId'" --only-show-errors 2>&1 | ConvertFrom-Json
        if ($spObjects -and $spObjects.Count -gt 0) {
            $spObjectId = $spObjects[0].id
            $spDisplayName = $spObjects[0].displayName
            Write-Check 'Service principal found' $true "$spDisplayName (Object ID: $spObjectId)"
            Add-CheckResult $true
        } else {
            Write-Check 'Service principal found' $false "No SP with appId=$ServicePrincipalAppId"
            Add-CheckResult $false
            $spObjectId = $null
        }
    } catch {
        Write-Check 'Service principal found' $false $_.Exception.Message
        Add-CheckResult $false
        $spObjectId = $null
    }

    if ($spObjectId) {
        $isMember = az ad group member check `
            --group $SqlAdminGroupId `
            --member-id $spObjectId `
            --only-show-errors 2>&1 | ConvertFrom-Json

        if ($isMember.value -eq $true) {
            Write-Check 'SP is member of SQL admin group' $true
            Add-CheckResult $true
        } else {
            Write-Check 'SP is member of SQL admin group' $false "Not a member of $($group.displayName)"
            if ($FixIssues) {
                Write-Action "Adding SP $spDisplayName to group $($group.displayName)..."
                az ad group member add `
                    --group $SqlAdminGroupId `
                    --member-id $spObjectId `
                    --only-show-errors 2>&1 | Out-Null
                Write-Check 'SP added to SQL admin group' $true '(fixed)'
                Add-CheckResult $false $true
            } else {
                Write-Info "Run with -FixIssues to add automatically, or manually:"
                Write-Info "  az ad group member add --group $SqlAdminGroupId --member-id $spObjectId"
                Add-CheckResult $false
            }
        }
    }
} else {
    Write-Info 'Skipped: No service principal specified (-ServicePrincipalAppId).'
}

# ── 4. Directory Readers Role ────────────────────────────────────────────────

Write-Section '4. Directory Readers Role for Admin Group'

Write-Info 'Checking if admin group has Directory Readers role...'
Write-Info '(Required to resolve managed identity names during CREATE USER FROM EXTERNAL PROVIDER)'

try {
    # Get the Directory Readers role definition
    $directoryReadersRoleId = '88d8e3e3-8f55-4a1e-953a-9b9898b8876b'

    $filterParam = "roleDefinitionId eq '$directoryReadersRoleId' and principalId eq '$SqlAdminGroupId'"
    $graphUrl = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?`$filter=$filterParam"

    $rawResponse = az rest --method GET --url $graphUrl --only-show-errors 2>&1
    $roleAssignments = $rawResponse | ConvertFrom-Json

    if ($roleAssignments.value -and $roleAssignments.value.Count -gt 0) {
        Write-Check 'Admin group has Directory Readers role' $true
        Add-CheckResult $true
    } else {
        Write-Check 'Admin group has Directory Readers role' $false
        if ($FixIssues) {
            Write-Action 'Assigning Directory Readers role to admin group...'
            $body = @{
                '@odata.type'    = '#microsoft.graph.unifiedRoleAssignment'
                roleDefinitionId = $directoryReadersRoleId
                principalId      = $SqlAdminGroupId
                directoryScopeId = '/'
            } | ConvertTo-Json -Compress

            try {
                az rest --method POST `
                    --url 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments' `
                    --headers 'Content-Type=application/json' `
                    --body $body `
                    --only-show-errors 2>&1 | Out-Null
                Write-Check 'Directory Readers role assigned' $true '(fixed)'
                Add-CheckResult $false $true
            } catch {
                Write-Check 'Directory Readers role assignment' $false `
                    'Needs Privileged Role Administrator. Assign manually in Entra ID portal.'
                Add-CheckResult $false
            }
        } else {
            Write-Info 'Run with -FixIssues to assign automatically, or assign manually:'
            Write-Info '  Entra ID > Roles and administrators > Directory Readers > Add assignment > select admin group'
            Add-CheckResult $false
        }
    }
} catch {
    Write-Check 'Directory Readers role check' $false "Graph API error: $($_.Exception.Message)"
    Write-Info 'You may lack Graph permissions. Check manually in Entra ID portal.'
    Add-CheckResult $false
}

# ── 5. Backend Managed Identity ──────────────────────────────────────────────

Write-Section '5. Backend App Service Managed Identity'

Write-Info "App Service: $backendAppName"

try {
    $webApp = az webapp identity show `
        --name $backendAppName `
        --resource-group $resourceGroup `
        --only-show-errors 2>&1 | ConvertFrom-Json

    if ($webApp.principalId) {
        Write-Check 'System-assigned managed identity enabled' $true "Principal: $($webApp.principalId)"
        Add-CheckResult $true
        $backendPrincipalId = $webApp.principalId
    } else {
        Write-Check 'System-assigned managed identity enabled' $false
        if ($FixIssues) {
            Write-Action 'Enabling system-assigned managed identity...'
            $result = az webapp identity assign `
                --name $backendAppName `
                --resource-group $resourceGroup `
                --only-show-errors 2>&1 | ConvertFrom-Json
            $backendPrincipalId = $result.principalId
            Write-Check 'Managed identity enabled' $true "(fixed) Principal: $backendPrincipalId"
            Add-CheckResult $false $true
        } else {
            Write-Info 'Run with -FixIssues to enable, or redeploy via deploy-infra workflow.'
            Add-CheckResult $false
            $backendPrincipalId = $null
        }
    }
} catch {
    Write-Check 'Backend App Service reachable' $false $_.Exception.Message
    Add-CheckResult $false
    $backendPrincipalId = $null
}

# ── 6. SQL Database User & Roles ─────────────────────────────────────────────

Write-Section '6. SQL Database User and Roles'

Write-Info "Database: $sqlServerName.database.windows.net / $databaseName"
Write-Info "Expected SQL user: [$backendAppName]"

try {
    # Get an access token for Azure SQL
    $token = az account get-access-token `
        --resource 'https://database.windows.net/' `
        --query 'accessToken' -o tsv 2>&1

    if (-not $token -or $token -match 'ERROR') {
        throw "Failed to get SQL access token: $token"
    }

    # Check if user exists and what roles they have
    $query = @"
SELECT
    dp.name AS [UserName],
    dp.type_desc AS [UserType],
    STRING_AGG(r.name, ', ') AS [Roles]
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = '$backendAppName'
GROUP BY dp.name, dp.type_desc;
"@

    $result = Invoke-Sqlcmd `
        -ServerInstance "$sqlServerName.database.windows.net" `
        -Database $databaseName `
        -AccessToken $token `
        -Query $query `
        -ErrorAction Stop

    if ($result) {
        Write-Check "SQL user [$backendAppName] exists" $true "Type: $($result.UserType)"
        Add-CheckResult $true

        $currentRoles = if ($result.Roles) { $result.Roles -split ', ' } else { @() }
        $requiredRoles = @('db_datareader', 'db_datawriter', 'db_ddladmin')
        $missingRoles = @()

        foreach ($role in $requiredRoles) {
            if ($currentRoles -contains $role) {
                Write-Check "  Role: $role" $true
                Add-CheckResult $true
            } else {
                Write-Check "  Role: $role" $false 'Missing'
                $missingRoles += $role
            }
        }

        if ($missingRoles.Count -gt 0 -and $FixIssues) {
            foreach ($role in $missingRoles) {
                Write-Action "Granting $role to [$backendAppName]..."
                Invoke-Sqlcmd `
                    -ServerInstance "$sqlServerName.database.windows.net" `
                    -Database $databaseName `
                    -AccessToken $token `
                    -Query "ALTER ROLE $role ADD MEMBER [$backendAppName];" `
                    -ErrorAction Stop
                Write-Check "  Role: $role" $true '(fixed)'
                Add-CheckResult $false $true
            }
        } elseif ($missingRoles.Count -gt 0) {
            Write-Info "Run with -FixIssues to grant missing roles automatically."
            foreach ($role in $missingRoles) { Add-CheckResult $false }
        }
    } else {
        Write-Check "SQL user [$backendAppName] exists" $false 'User not found in database'

        if ($FixIssues) {
            Write-Action "Creating SQL user [$backendAppName] from external provider..."
            Invoke-Sqlcmd `
                -ServerInstance "$sqlServerName.database.windows.net" `
                -Database $databaseName `
                -AccessToken $token `
                -Query "CREATE USER [$backendAppName] FROM EXTERNAL PROVIDER;" `
                -ErrorAction Stop
            Write-Check "SQL user [$backendAppName] created" $true '(fixed)'
            Add-CheckResult $false $true

            foreach ($role in @('db_datareader', 'db_datawriter', 'db_ddladmin')) {
                Write-Action "Granting $role to [$backendAppName]..."
                Invoke-Sqlcmd `
                    -ServerInstance "$sqlServerName.database.windows.net" `
                    -Database $databaseName `
                    -AccessToken $token `
                    -Query "ALTER ROLE $role ADD MEMBER [$backendAppName];" `
                    -ErrorAction Stop
                Write-Check "  Role: $role" $true '(fixed)'
                Add-CheckResult $false $true
            }
        } else {
            Write-Info "Run with -FixIssues to create user and grant roles."
            Add-CheckResult $false
        }
    }
} catch {
    Write-Check 'SQL Database connection' $false $_.Exception.Message
    Write-Info 'Possible causes:'
    Write-Info '  - Firewall rule missing for your IP'
    Write-Info '  - Access token expired or insufficient permissions'
    Write-Info '  - SqlServer PowerShell module not installed (Install-Module SqlServer)'
    Add-CheckResult $false
}

# ── 7. SQL Server Firewall ───────────────────────────────────────────────────

Write-Section '7. SQL Server Firewall Rules'

$firewallRules = az sql server firewall-rule list `
    --server $sqlServerName `
    --resource-group $resourceGroup `
    --only-show-errors 2>&1 | ConvertFrom-Json

if ($firewallRules) {
    foreach ($rule in $firewallRules) {
        $range = if ($rule.startIpAddress -eq $rule.endIpAddress) {
            $rule.startIpAddress
        } else {
            "$($rule.startIpAddress) - $($rule.endIpAddress)"
        }
        Write-Check "Firewall: $($rule.name)" $true $range
    }

    $hasAzureRule = $firewallRules | Where-Object {
        $_.startIpAddress -eq '0.0.0.0' -and $_.endIpAddress -eq '0.0.0.0'
    }
    Write-Check 'Allow Azure Services rule' ([bool]$hasAzureRule)
    Add-CheckResult ([bool]$hasAzureRule)
} else {
    Write-Check 'Firewall rules exist' $false 'No rules found'
    Add-CheckResult $false
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Section 'Summary'

Write-Host "Total checks:  $totalChecks"
Write-Host "Passed:        $passedChecks" -ForegroundColor Green
if ($fixedChecks -gt 0) {
    Write-Host "Fixed:         $fixedChecks" -ForegroundColor Yellow
}
if ($failedChecks -gt 0) {
    Write-Host "Failed:        $failedChecks" -ForegroundColor Red
    if (-not $FixIssues) {
        Write-Host ''
        Write-Host 'Run with -FixIssues to automatically fix issues where possible.' -ForegroundColor Yellow
    }
}

Write-Host ''
if ($failedChecks -eq 0) {
    Write-Host 'All permissions are correctly configured.' -ForegroundColor Green
    exit 0
} else {
    Write-Host 'Some checks failed. Review the output above.' -ForegroundColor Red
    exit 1
}
