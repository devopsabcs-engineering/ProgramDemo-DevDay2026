metadata name = 'Storage Account'
metadata description = 'Deploys an Azure Storage Account for Azure Functions runtime and general storage.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Resource ID of the scripts subnet (snet-scripts). Used to allow the deployment script container to access the storage account via VNet service endpoint.')
param scriptsSubnetId string = ''

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
    networkAcls: {
      // 'AzureServices' allows deployment scripts and other trusted Azure services
      // to bypass the firewall. Required when using deploymentScripts with VNet subnets.
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      virtualNetworkRules: !empty(scriptsSubnetId) ? [
        {
          // Allow the snet-scripts subnet (ACI containers running deployment scripts)
          // to reach the storage account via the Microsoft.Storage service endpoint.
          id: scriptsSubnetId
          action: 'Allow'
        }
      ] : []
    }
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the storage account.')
output id string = storageAccount.id

@description('The name of the storage account.')
output name string = storageAccount.name
