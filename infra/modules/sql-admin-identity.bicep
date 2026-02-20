metadata name = 'SQL Admin Managed Identity'
metadata description = 'Creates a user-assigned managed identity used as the Azure SQL AAD administrator and as the identity for deployment script execution.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Resources ─── */

resource sqlAdminIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-sql-admin-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
}

/* ─── Outputs ─── */

@description('The resource ID of the managed identity.')
output id string = sqlAdminIdentity.id

@description('The client (application) ID of the managed identity. Used as msiClientId in the JDBC connection string.')
output clientId string = sqlAdminIdentity.properties.clientId

@description('The principal (object) ID of the managed identity. Used as the SQL AAD administrator sid and for RBAC role assignments.')
output principalId string = sqlAdminIdentity.properties.principalId

@description('The name of the managed identity.')
output name string = sqlAdminIdentity.name
