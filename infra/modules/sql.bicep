metadata name = 'SQL Server and Database'
metadata description = 'Deploys an Azure SQL Server and a SQL Database accessible only via a private endpoint. Public network access is disabled.'

import { DeploymentConfig, SqlConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('SQL Server and database configuration.')
param sqlConfig SqlConfig

@description('SQL Database name suffix.')
param databaseName string = 'programdb'

@description('Resource ID of the private endpoint subnet.')
param privateEndpointSubnetId string

@description('Resource ID of the VNet for private DNS zone linking.')
param vnetId string

@description('Name of the user-assigned managed identity acting as the SQL AAD administrator.')
param adminIdentityName string

@description('Principal (Object) ID of the user-assigned managed identity acting as the SQL AAD administrator. SQL Server stores this as the admin sid and compares it against the oid claim in the incoming AAD token. Must be principalId, NOT clientId.')
param adminIdentityPrincipalId string

@description('Client ID of the user-assigned managed identity that the App Service uses to authenticate to SQL. Embedded in the JDBC connection string as msiClientId.')
param appMsiClientId string

/* ─── Resources ─── */

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    // Public access is disabled; connectivity is via private endpoint only.
    // Azure Policy enforces this — do not change to Enabled.
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      // The SQL AAD admin is a user-assigned managed identity so that
      // deployment scripts in the VNet can authenticate and provision DB users.
      // Human DBA access should be added separately (e.g., via db_owner role).
      login: adminIdentityName
      sid: adminIdentityPrincipalId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: true
      principalType: 'Application'
    }
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

/* ─── Private DNS Zone ─── */

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
  tags: config.tags
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

/* ─── Private Endpoint ─── */

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-sql-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-sql-${config.prefix}-${config.environment}-${config.instanceNumber}'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlServer']
        }
      }
    ]
  }
}

resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'dnszonegroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-database-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
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
output jdbcConnectionString string = 'jdbc:sqlserver://${sqlServer.properties.fullyQualifiedDomainName}:1433;database=${sqlDatabase.name};encrypt=true;trustServerCertificate=true;hostNameInCertificate=*.database.windows.net;loginTimeout=30;authentication=ActiveDirectoryManagedIdentity;msiClientId=${appMsiClientId};'
