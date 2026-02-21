metadata name = 'Azure Container Registry'
metadata description = 'Deploys an Azure Container Registry for storing Docker images.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('SKU for the container registry. Premium is required for private endpoint support.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Premium'

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
    // Public network access must remain Enabled for GitHub Actions CI/CD
    // to build and push images via `az acr build`. The ACR firewall uses
    // the default 'Allow' action. If Azure Policy requires Disabled,
    // switch to a self-hosted runner inside the VNet or use ACR import.
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the container registry.')
output id string = containerRegistry.id

@description('The name of the container registry.')
output name string = containerRegistry.name

@description('The login server of the container registry.')
output loginServer string = containerRegistry.properties.loginServer

@description('The admin username for the container registry.')
#disable-next-line outputs-should-not-contain-secrets
output adminUsername string = containerRegistry.listCredentials().username

@description('The first admin password for the container registry.')
#disable-next-line outputs-should-not-contain-secrets
output adminPassword string = containerRegistry.listCredentials().passwords[0].value
