metadata name = 'Function App Managed Identity'
metadata description = 'Creates a user-assigned managed identity for the Function App. A user-assigned identity is required so that RBAC roles can be granted before the Function App is provisioned, avoiding the chicken-and-egg problem with identity-based storage connections.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Resources ─── */

resource functionIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-func-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
}

/* ─── Outputs ─── */

@description('The resource ID of the managed identity.')
output id string = functionIdentity.id

@description('The client (application) ID of the managed identity.')
output clientId string = functionIdentity.properties.clientId

@description('The principal (object) ID of the managed identity.')
output principalId string = functionIdentity.properties.principalId

@description('The name of the managed identity.')
output name string = functionIdentity.name
