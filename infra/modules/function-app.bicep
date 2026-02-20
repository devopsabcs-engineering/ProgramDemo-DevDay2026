metadata name = 'Function App'
metadata description = 'Deploys an Azure Function App on a Consumption plan for Durable Functions workflow orchestration. Uses identity-based storage connections (no shared keys) to comply with Azure Policy.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Name of the storage account used by the Function App runtime.')
param storageAccountName string

@description('Resource ID of the user-assigned managed identity for storage access.')
param userAssignedIdentityId string

@description('Client (application) ID of the user-assigned managed identity.')
param userAssignedIdentityClientId string

@description('Name of the pre-created file share for function content.')
param contentShareName string

@description('Additional application settings to merge into the Function App configuration.')
param additionalAppSettings array = []

/* ─── Variables ─── */

var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage__accountName'
    value: storageAccountName
  }
  {
    name: 'AzureWebJobsStorage__credential'
    value: 'managedidentity'
  }
  {
    name: 'AzureWebJobsStorage__clientId'
    value: userAssignedIdentityClientId
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: contentShareName
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'dotnet-isolated'
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
]

var allAppSettings = concat(baseAppSettings, additionalAppSettings)

/* ─── Resources ─── */

resource consumptionPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-${config.prefix}-func-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'func-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: consumptionPlan.id
    httpsOnly: true
    keyVaultReferenceIdentity: userAssignedIdentityId
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v8.0'
      appSettings: allAppSettings
    }
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the Function App.')
output id string = functionApp.id

@description('The name of the Function App.')
output name string = functionApp.name

@description('The default hostname of the Function App.')
output defaultHostName string = functionApp.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity.')
output principalId string = functionApp.identity.principalId
