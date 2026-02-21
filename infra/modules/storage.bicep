metadata name = 'Storage Account'
metadata description = 'Deploys an Azure Storage Account for Azure Functions runtime and general storage.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Variables ─── */

@description('Globally unique storage account name derived from resource group.')
var storageAccountName = take('st${replace(config.prefix, '-', '')}${config.environment}${config.instanceNumber}${uniqueString(resourceGroup().id)}', 24)

/* ─── Resources ─── */

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: config.location
  tags: config.tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    // Azure Policy blocks shared-key access on this subscription.
    // The Function App uses identity-based storage connections instead.
    allowSharedKeyAccess: false
    networkAcls: {
      // 'AzureServices' lets the deployment script service (a trusted Azure service)
      // access the storage account for its scratch file share, even when the
      // storage account has no public VNet rules.
      // Do NOT add virtualNetworkRules here — any VNet rule causes Azure to treat
      // the firewall as "enabled" which breaks deploymentScript (BCP error
      // DeploymentScriptStorageAccountWithServiceEndpointEnabled).
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      virtualNetworkRules: []
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource programDocumentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'program-documents'
  properties: {
    publicAccess: 'None'
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the storage account.')
output id string = storageAccount.id

@description('The name of the storage account.')
output name string = storageAccount.name

@description('Blob service URI for use in application configuration.')
output blobServiceUri string = storageAccount.properties.primaryEndpoints.blob
