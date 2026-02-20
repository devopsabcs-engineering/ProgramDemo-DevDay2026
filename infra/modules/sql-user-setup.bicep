metadata name = 'SQL User Setup Deployment Script'
metadata description = 'Runs a deployment script inside the VNet to create the App Service managed identity as a SQL database user. This avoids the need for direct SQL connectivity from the GitHub Actions runner.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Fully qualified domain name of the SQL Server.')
param sqlServerFqdn string

@description('Name of the SQL database.')
param dbName string = 'programdb'

@description('Name of the App Service whose managed identity needs SQL access.')
param appPrincipalName string

@description('Resource ID of the scripts subnet (delegated to Microsoft.ContainerInstance/containerGroups).')
param scriptsSubnetId string

@description('Resource ID of the user-assigned managed identity that is the SQL AAD administrator.')
param adminIdentityId string

@description('Name of the storage account used for deployment script scratch storage.')
param storageAccountName string

@description('Force re-run on every deployment. Defaults to the current UTC timestamp so the script always runs.')
param forceUpdateTag string = utcNow()

/* ─── Resources ─── */

resource sqlUserSetup 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'ds-sql-user-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${adminIdentityId}': {}
    }
  }
  properties: {
    azCliVersion: '2.67.0'
    retentionInterval: 'PT1H'
    timeout: 'PT15M'
    forceUpdateTag: forceUpdateTag
    storageAccountSettings: {
      storageAccountName: storageAccountName
    }
    containerSettings: {
      // Run the container inside the VNet so it can reach the SQL private endpoint.
      subnetIds: [
        { id: scriptsSubnetId }
      ]
    }
    environmentVariables: [
      { name: 'SQL_FQDN',     value: sqlServerFqdn    }
      { name: 'DB_NAME',      value: dbName           }
      { name: 'APP_PRINCIPAL', value: appPrincipalName }
    ]
    // The managed identity attached above is the SQL AAD admin, so sqlcmd connects
    // with ActiveDirectoryManagedIdentity and has full ddl / dml rights.
    scriptContent: '''
      #!/bin/bash
      set -euo pipefail

      echo "Installing go-sqlcmd..."
      curl -fsSL \
        https://github.com/microsoft/go-sqlcmd/releases/latest/download/sqlcmd-linux-amd64.tar.bz2 \
        -o /tmp/sqlcmd.tar.bz2
      tar -xjf /tmp/sqlcmd.tar.bz2 -C /usr/local/bin
      rm -f /tmp/sqlcmd.tar.bz2
      echo "sqlcmd $(sqlcmd --version)"

      echo "Provisioning SQL user [${APP_PRINCIPAL}] on ${SQL_FQDN}/${DB_NAME}..."
      sqlcmd \
        -S "${SQL_FQDN}" \
        -d "${DB_NAME}" \
        --authentication-method=ActiveDirectoryManagedIdentity \
        -Q "
          IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${APP_PRINCIPAL}')
          BEGIN
            CREATE USER [${APP_PRINCIPAL}] FROM EXTERNAL PROVIDER;
            PRINT 'Created user [${APP_PRINCIPAL}].';
          END
          ELSE
            PRINT 'User [${APP_PRINCIPAL}] already exists.';

          IF IS_ROLEMEMBER('db_datareader', '${APP_PRINCIPAL}') = 0
            ALTER ROLE db_datareader ADD MEMBER [${APP_PRINCIPAL}];
          IF IS_ROLEMEMBER('db_datawriter', '${APP_PRINCIPAL}') = 0
            ALTER ROLE db_datawriter ADD MEMBER [${APP_PRINCIPAL}];
          IF IS_ROLEMEMBER('db_ddladmin',   '${APP_PRINCIPAL}') = 0
            ALTER ROLE db_ddladmin   ADD MEMBER [${APP_PRINCIPAL}];

          PRINT 'Roles: db_datareader, db_datawriter, db_ddladmin granted.';
        "
      echo "SQL user setup complete."
    '''
  }
}
