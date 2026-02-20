metadata name = 'Web App'
metadata description = 'Deploys an Azure App Service web application on an existing App Service Plan.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Short suffix to distinguish this web app (e.g., api, web).')
param appSuffix string

@description('Resource ID of the App Service Plan to host this web app.')
param appServicePlanId string

@description('Runtime stack for the web app (e.g., JAVA|21-java21, NODE|20-lts, DOCKER|<registry>/<image>:<tag>).')
param linuxFxVersion string

@description('Application settings as key-value pairs.')
param appSettings array = []

@description('Docker registry server URL (e.g., https://myacr.azurecr.io). Leave empty for non-container deployments.')
param dockerRegistryServerUrl string = ''

@description('Docker registry username. Leave empty for non-container deployments.')
param dockerRegistryUsername string = ''

@description('Docker registry password. Leave empty for non-container deployments.')
@secure()
param dockerRegistryPassword string = ''

@description('Custom startup command for the web app (e.g., pm2 serve command). Leave empty to use the container ENTRYPOINT or platform default.')
param startupCommand string = ''

@description('Resource ID of the VNet integration subnet. Leave empty to skip VNet integration.')
param vnetSubnetId string = ''

@description('Resource ID of a user-assigned managed identity to attach. Leave empty for system-assigned only.')
param userAssignedIdentityId string = ''

/* ─── Variables ─── */

// Merge Docker registry settings into app settings when using a container image
var dockerSettings = !empty(dockerRegistryServerUrl) ? [
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: dockerRegistryServerUrl
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
    value: dockerRegistryUsername
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
    value: dockerRegistryPassword
  }
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
] : []

var allAppSettings = concat(appSettings, dockerSettings)

/* ─── Resources ─── */

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'app-${config.prefix}-${appSuffix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  // When a user-assigned identity is provided, attach it alongside the system-assigned
  // identity so the app can authenticate to Azure services as either identity.
  identity: !empty(userAssignedIdentityId) ? {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    // Wire VNet integration when a subnet ID is supplied
    virtualNetworkSubnetId: !empty(vnetSubnetId) ? vnetSubnetId : null
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appCommandLine: startupCommand
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      // Route all outbound traffic through VNet so private endpoint DNS resolves correctly
      vnetRouteAllEnabled: !empty(vnetSubnetId)
      appSettings: allAppSettings
    }
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the web app.')
output id string = webApp.id

@description('The name of the web app.')
output name string = webApp.name

@description('The default hostname of the web app.')
output defaultHostName string = webApp.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity.')
output principalId string = webApp.identity.principalId
