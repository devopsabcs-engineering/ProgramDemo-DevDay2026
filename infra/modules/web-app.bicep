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

@description('Runtime stack for the web app (e.g., JAVA|21-java21, NODE|20-lts).')
param linuxFxVersion string

@description('Application settings as key-value pairs.')
param appSettings array = []

/* ─── Resources ─── */

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'app-${config.prefix}-${appSuffix}-${config.environment}'
  location: config.location
  tags: config.tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: appSettings
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
