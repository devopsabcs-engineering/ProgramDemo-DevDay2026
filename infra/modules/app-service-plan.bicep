metadata name = 'App Service Plan'
metadata description = 'Deploys a Linux App Service Plan for hosting web applications.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('App Service Plan SKU name.')
param skuName string

@description('Number of workers for the App Service Plan.')
param capacity int = 1

/* ─── Resources ─── */

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-${config.prefix}-${config.environment}'
  location: config.location
  tags: config.tags
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: skuName
    capacity: capacity
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the App Service Plan.')
output id string = appServicePlan.id

@description('The name of the App Service Plan.')
output name string = appServicePlan.name
