metadata name = 'Function App'
metadata description = 'Deploys an Azure Function App on a Dedicated (Basic) plan for Durable Functions workflow orchestration. Uses identity-based storage connections (no shared keys) to comply with Azure Policy. A Dedicated plan avoids the WEBSITE_CONTENTAZUREFILECONNECTIONSTRING requirement that Consumption and Elastic Premium plans impose.'

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

@description('Additional application settings to merge into the Function App configuration.')
param additionalAppSettings array = []

/* ─── Variables ─── */

// Dedicated plans use the local file system for function code — no
// WEBSITE_CONTENTAZUREFILECONNECTIONSTRING or WEBSITE_CONTENTSHARE needed.
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
  {
    name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
    value: '1'
  }
]

var allAppSettings = concat(baseAppSettings, additionalAppSettings)

/* ─── Resources ─── */

resource functionPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-${config.prefix}-func-ded-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  sku: {
    name: 'B1'
    tier: 'Basic'
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
    serverFarmId: functionPlan.id
    httpsOnly: true
    keyVaultReferenceIdentity: userAssignedIdentityId
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v8.0'
      use32BitWorkerProcess: false
      alwaysOn: true
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
