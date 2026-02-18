metadata name = 'SQL Server and Database'
metadata description = 'Deploys an Azure SQL Server and a SQL Database with firewall rules.'

import { DeploymentConfig, SqlConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('SQL Server and database configuration.')
param sqlConfig SqlConfig

@description('SQL Database name suffix.')
param databaseName string = 'programdb'

/* ─── Resources ─── */

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      login: sqlConfig.aadAdminLogin
      sid: sqlConfig.aadAdminObjectId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: true
      principalType: 'Group'
    }
  }
}

resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (sqlConfig.isAllowAzureServicesEnabled) {
  parent: sqlServer
  name: 'AllowAllAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: config.location
  tags: config.tags
  sku: {
    name: sqlConfig.skuName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

/* ─── Outputs ─── */

@description('The fully qualified domain name of the SQL Server.')
output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName

@description('The name of the SQL Server.')
output serverName string = sqlServer.name

@description('The name of the SQL Database.')
output databaseName string = sqlDatabase.name

@description('The JDBC connection string for the database (Azure AD auth).')
output jdbcConnectionString string = 'jdbc:sqlserver://${sqlServer.properties.fullyQualifiedDomainName}:1433;database=${sqlDatabase.name};encrypt=true;trustServerCertificate=true;hostNameInCertificate=*.database.windows.net;loginTimeout=30;authentication=ActiveDirectoryDefault;'
