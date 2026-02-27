metadata name = 'Deployment Scripts Storage Account'
metadata description = 'Dedicated storage account for Azure deployment scripts scratch storage. Kept separate from the main storage account to avoid Azure Policy-injected resourceAccessRules (e.g., Microsoft Defender StorageDataScanner) which cause DeploymentScriptStorageAccountWithServiceEndpointEnabled errors. Policy rules are applied asynchronously and will not be present on a freshly provisioned account during the same ARM deployment cycle.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Variables ─── */

var storageAccountName = take('stscript${replace(config.prefix, '-', '')}${config.environment}${config.instanceNumber}${uniqueString(resourceGroup().id)}', 24)

/* ─── Resources ─── */

resource scriptsStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
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
      // 'AzureServices' bypass is required for the deploymentScript service.
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      // Explicitly empty — prevents Azure Defender for Storage (StorageDataScanner)
      // resourceAccessRules from being present at script execution time.
      // These rules are applied by Azure Policy asynchronously; setting [] here
      // ensures a clean state when the deployment script runs in the same ARM cycle.
      resourceAccessRules: []
      virtualNetworkRules: []
      ipRules: []
    }
  }
}

/* ─── Outputs ─── */

@description('The name of the scripts storage account.')
output name string = scriptsStorage.name
