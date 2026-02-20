metadata name = 'OPS Program Demo Infrastructure'
metadata description = 'Main orchestration template for the OPS Program Approval System. Deploys all Azure resources required for the Developer Day 2026 demo.'

import { DeploymentConfig, SqlConfig, AppServicePlanConfig } from './types.bicep'

/* ─── Common Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

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

module backendApp './modules/web-app.bicep' = {
  params: {
    config: config
    appSuffix: 'api'
    appServicePlanId: appServicePlan.outputs.id
    linuxFxVersion: 'DOCKER|${containerRegistry.outputs.loginServer}/program-demo-api:latest'
    dockerRegistryServerUrl: 'https://${containerRegistry.outputs.loginServer}'
    dockerRegistryUsername: containerRegistry.outputs.adminUsername
    dockerRegistryPassword: containerRegistry.outputs.adminPassword
    vnetSubnetId: vnet.outputs.appSubnetId
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
    adminIdentityClientId: sqlAdminIdentity.outputs.clientId
  }
}

// Grant the SQL admin managed identity Storage Account Contributor on the storage
// account so the deployment script can use it for its scratch file share.
// Uses a dedicated module because role assignment name/scope must be resolvable
// within a module boundary, not from parent module outputs directly.
module sqlAdminStorageRole './modules/storage-role-assignment.bicep' = {
  name: 'sqlAdminStorageRole'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: sqlAdminIdentity.outputs.principalId
    // Storage Account Contributor
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }
}

// Deployment script that runs inside the VNet to create the App Service
// managed identity as a SQL user. Replaces the sqlcmd workflow step which
// can no longer reach SQL now that public network access is disabled.
module sqlUserSetup './modules/sql-user-setup.bicep' = {
  params: {
    config: config
    sqlServerFqdn: sqlServer.outputs.fullyQualifiedDomainName
    appPrincipalName: backendApp.outputs.name
    scriptsSubnetId: vnet.outputs.scriptsSubnetId
    adminIdentityId: sqlAdminIdentity.outputs.id
    storageAccountName: storageAccount.outputs.name
  }
  dependsOn: [sqlAdminStorageRole]
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
