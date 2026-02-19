metadata name = 'Azure Container Registry'
metadata description = 'Deploys an Azure Container Registry for storing Docker images.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('SKU for the container registry.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Basic'

/* ─── Variables ─── */

// ACR names must be globally unique, alphanumeric, 5-50 chars
var registryName = replace('acr${config.prefix}${config.environment}${config.instanceNumber}', '-', '')

/* ─── Resources ─── */

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: registryName
  location: config.location
  tags: config.tags
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the container registry.')
output id string = containerRegistry.id

@description('The name of the container registry.')
output name string = containerRegistry.name

@description('The login server of the container registry.')
output loginServer string = containerRegistry.properties.loginServer
