metadata name = 'OPS Program Demo Infrastructure'
metadata description = 'Main orchestration template for the OPS Program Approval System. Deploys all Azure resources required for the Developer Day 2026 demo.'

import { DeploymentConfig, SqlConfig, AppServicePlanConfig } from './types.bicep'

/* ─── Deployment Identity Parameters ─── */

@description('Resource name prefix for all resources (e.g. ops-demo).')
param prefix string = 'ops-demo'

@description('Azure region for resource deployment.')
param location string = 'canadacentral'

@description('Deployment environment.')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Instance number for resource naming (e.g. 125). Required — no default.')
param instanceNumber string

@description('Tags applied to all resources.')
param tags object = {
  project: 'OPS-ProgramDemo'
  environment: environment
  managedBy: 'bicep'
  demo: 'DevDay2026'
}

// Assemble the shared config object from flat params so the workflow can
// override environment and instanceNumber with --parameters on the CLI.
var config = {
  prefix: prefix
  location: location
  environment: environment
  instanceNumber: instanceNumber
  tags: tags
}

/* ─── App Service Parameters ─── */

@description('App Service Plan SKU configuration.')
param appServicePlanConfig AppServicePlanConfig

/* ─── SQL Parameters ─── */

@description('SQL Server and database configuration.')
param sqlConfig SqlConfig

/* ─── Modules: Shared Infrastructure ─── */

module vnet './modules/vnet.bicep' = {
  params: {
    config: config
  }
}

// User-assigned managed identity that acts as the SQL AAD administrator.
// It is also the identity used by the sql-user-setup deployment script.
module sqlAdminIdentity './modules/sql-admin-identity.bicep' = {
  params: {
    config: config
  }
}

module storageAccount './modules/storage.bicep' = {
  params: {
    config: config
  }
}

module appServicePlan './modules/app-service-plan.bicep' = {
  params: {
    config: config
    skuName: appServicePlanConfig.skuName
    capacity: appServicePlanConfig.capacity
  }
}

module containerRegistry './modules/container-registry.bicep' = {
  params: {
    config: config
    skuName: 'Basic'
  }
}

/* ─── Modules: Web Applications ─── */

// Grant the SQL admin MI the AcrPull role so the App Service can pull images
// using managed identity credentials (acrUseManagedIdentityCreds: true).
// AcrPull role definition ID: 7f951dda-4ed3-4680-a7ca-43fe172d538d
module acrPullRole './modules/acr-role-assignment.bicep' = {
  params: {
    registryName: containerRegistry.outputs.name
    principalId: sqlAdminIdentity.outputs.principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
}

module backendApp './modules/web-app.bicep' = {
  params: {
    config: config
    appSuffix: 'api'
    appServicePlanId: appServicePlan.outputs.id
    linuxFxVersion: 'DOCKER|${containerRegistry.outputs.loginServer}/program-demo-api:latest'
    dockerRegistryServerUrl: 'https://${containerRegistry.outputs.loginServer}'
    // Use managed identity for ACR pull — no admin password needed.
    // The MI (sqlAdminIdentity) has AcrPull role assigned above.
    acrUserManagedIdentityClientId: sqlAdminIdentity.outputs.clientId
    vnetSubnetId: vnet.outputs.appSubnetId
    // Attach the SQL admin managed identity so the app authenticates to SQL
    // as the AAD administrator — no separate user provisioning step needed.
    userAssignedIdentityId: sqlAdminIdentity.outputs.id
    appSettings: [
      {
        name: 'SPRING_DATASOURCE_URL'
        value: sqlServer.outputs.jdbcConnectionString
      }
      {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: ''
      }
      {
        name: 'SPRING_DATASOURCE_PASSWORD'
        value: ''
      }
      {
        name: 'WEBSITES_PORT'
        value: '8080'
      }
      {
        name: 'APP_CORS_ALLOWED_ORIGIN'
        value: 'https://app-${config.prefix}-web-${config.environment}-${config.instanceNumber}.azurewebsites.net'
      }
    ]
  }
}

module frontendApp './modules/web-app.bicep' = {
  params: {
    config: config
    appSuffix: 'web'
    appServicePlanId: appServicePlan.outputs.id
    linuxFxVersion: 'NODE|20-lts'
    startupCommand: 'pm2 serve /home/site/wwwroot --no-daemon --spa'
    appSettings: [
      {
        name: 'WEBSITE_NODE_DEFAULT_VERSION'
        value: '~20'
      }
    ]
  }
}

/* ─── Modules: Database ─── */

module sqlServer './modules/sql.bicep' = {
  params: {
    config: config
    sqlConfig: sqlConfig
    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
    vnetId: vnet.outputs.vnetId
    adminIdentityName: sqlAdminIdentity.outputs.name
    // sid in the SQL AAD admin block must be the Object ID (principalId).
    // SQL Server verifies it against the oid claim in the incoming token.
    adminIdentityPrincipalId: sqlAdminIdentity.outputs.principalId
    // msiClientId in the JDBC URL must be the Application/Client ID so the
    // MSSQL driver requests a token scoped to the correct user-assigned MI.
    appMsiClientId: sqlAdminIdentity.outputs.clientId
  }
}

/* ─── Modules: Workflow and Notifications ─── */

module functionApp './modules/function-app.bicep' = {
  params: {
    config: config
    storageAccountName: storageAccount.outputs.name
  }
}

module logicApp './modules/logic-app.bicep' = {
  params: {
    config: config
  }
}

/* ─── Outputs ─── */

@description('The default hostname of the backend API.')
output backendUrl string = backendApp.outputs.defaultHostName

@description('The default hostname of the frontend web app.')
output frontendUrl string = frontendApp.outputs.defaultHostName

@description('The fully qualified domain name of the SQL Server.')
output sqlServerFqdn string = sqlServer.outputs.fullyQualifiedDomainName

@description('The default hostname of the Function App.')
output functionAppUrl string = functionApp.outputs.defaultHostName

@description('The name of the Logic App.')
output logicAppName string = logicApp.outputs.name

@description('The principal ID of the backend API managed identity.')
output backendPrincipalId string = backendApp.outputs.principalId

@description('The login server of the container registry.')
output acrLoginServer string = containerRegistry.outputs.loginServer

@description('The name of the container registry.')
output acrName string = containerRegistry.outputs.name
