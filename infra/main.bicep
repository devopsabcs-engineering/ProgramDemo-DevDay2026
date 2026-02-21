metadata name = 'OPS Program Demo Infrastructure'
metadata description = 'Main orchestration template for the OPS Program Approval System. Deploys all Azure resources required for the Developer Day 2026 demo.'

import { SqlConfig, AppServicePlanConfig } from './types.bicep'

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

// Private endpoints for blob, queue, table, and file services so the
// Function App (via VNet integration) can reach storage when public
// network access is disabled by Azure Policy.
module storagePrivateEndpoints './modules/storage-private-endpoints.bicep' = {
  name: 'storagePrivateEndpoints'
  params: {
    config: config
    storageAccountName: storageAccount.outputs.name
    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
    vnetId: vnet.outputs.vnetId
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
    // Premium SKU required for private endpoint support.
    // Azure Policy may deny public network access on lower SKUs.
    skuName: 'Premium'
  }
}

// Private endpoint for ACR so the App Service can pull container images
// via VNet integration when public network access is restricted.
module acrPrivateEndpoint './modules/acr-private-endpoint.bicep' = {
  name: 'acrPrivateEndpoint'
  params: {
    config: config
    registryName: containerRegistry.outputs.name
    registryId: containerRegistry.outputs.id
    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
    vnetId: vnet.outputs.vnetId
  }
}

/* ─── Modules: Observability ─── */

module appInsights './modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    config: config
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
  // Ensure all private endpoints are deployed before the app starts,
  // so DNS resolves to private IPs and outbound connections succeed.
  dependsOn: [
    storagePrivateEndpoints
    acrPrivateEndpoint
  ]
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
      {
        name: 'AZURE_STORAGE_BLOB_SERVICE_URI'
        value: storageAccount.outputs.blobServiceUri
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.connectionString
      }
      {
        name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
        value: '600'
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
      {
        // The frontend is a static SPA served by PM2. Application Insights
        // telemetry is handled by the browser SDK (@microsoft/applicationinsights-web)
        // with VITE_APPINSIGHTS_CONNECTION_STRING baked at build time.
        // Server-side codeless auto-instrumentation (IPA) must be disabled to
        // prevent it from interfering with PM2 and causing a container crash loop.
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~0'
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

/* ─── Modules: AI Services ─── */

module documentIntelligence './modules/document-intelligence.bicep' = {
  name: 'documentIntelligence'
  params: {
    config: config
  }
}

module openAi './modules/openai.bicep' = {
  name: 'openAi'
  params: {
    config: config
    location: 'eastus'
    chatModelDeploymentName: 'gpt-4o-mini'
  }
}

// Private endpoints for Document Intelligence and Azure OpenAI so the
// Function App (via VNet integration) can reach them when Azure Policy
// denies public network access on Cognitive Services accounts.
module cognitivePrivateEndpoints './modules/cognitive-private-endpoints.bicep' = {
  name: 'cognitivePrivateEndpoints'
  params: {
    config: config
    docIntelligenceName: documentIntelligence.outputs.name
    docIntelligenceId: documentIntelligence.outputs.id
    openAiName: openAi.outputs.name
    openAiId: openAi.outputs.id
    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
    vnetId: vnet.outputs.vnetId
  }
}

/* ─── Modules: Workflow and Notifications ─── */

// User-assigned managed identity for the Function App.
// Created before the Function App so that RBAC roles can be granted
// before Azure tries to mount the identity-based storage file share.
module functionIdentity './modules/function-identity.bicep' = {
  name: 'functionIdentity'
  params: {
    config: config
  }
}

// Pre-assign storage roles to the Function App MI so that identity-based
// storage connections work during initial provisioning.
// Storage Blob Data Owner — blob operations + lease management
module funcStorageBlobOwner './modules/storage-role-assignment.bicep' = {
  name: 'funcStorageBlobOwner'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionIdentity.outputs.principalId
    roleDefinitionId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  }
}

// Storage Queue Data Contributor — internal queue messaging
module funcStorageQueueContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcStorageQueueContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionIdentity.outputs.principalId
    roleDefinitionId: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  }
}

// Storage Table Data Contributor — timer trigger / durable functions history
module funcStorageTableContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcStorageTableContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionIdentity.outputs.principalId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
  }
}

// Storage Account Contributor — manage storage account properties (user MI)
module funcStorageAccountContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcStorageAccountContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionIdentity.outputs.principalId
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }
}

// Storage File Data Privileged Contributor — file share access for runtime (user MI)
module funcStorageFileContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcStorageFileContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionIdentity.outputs.principalId
    roleDefinitionId: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
  }
}

module functionApp './modules/function-app.bicep' = {
  name: 'functionApp'
  dependsOn: [
    funcStorageBlobOwner
    funcStorageQueueContributor
    funcStorageTableContributor
    funcStorageAccountContributor
    funcStorageFileContributor
    storagePrivateEndpoints
    cognitivePrivateEndpoints
  ]
  params: {
    config: config
    storageAccountName: storageAccount.outputs.name
    userAssignedIdentityId: functionIdentity.outputs.id
    userAssignedIdentityClientId: functionIdentity.outputs.clientId
    vnetSubnetId: vnet.outputs.appSubnetId
    additionalAppSettings: [
      {
        name: 'DOCUMENT_INTELLIGENCE_ENDPOINT'
        value: documentIntelligence.outputs.endpoint
      }
      {
        name: 'AZURE_OPENAI_ENDPOINT'
        value: openAi.outputs.endpoint
      }
      {
        name: 'AZURE_OPENAI_DEPLOYMENT'
        value: openAi.outputs.deploymentName
      }
      {
        name: 'API_BASE_URL'
        value: 'https://${backendApp.outputs.defaultHostName}'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.connectionString
      }
    ]
  }
}

/* ─── RBAC: Storage Blob Data Contributor (backend upload) ─── */
// Role ID: ba92f5b4-2d11-453d-a403-e96b0029c9fe

module backendBlobRole './modules/storage-role-assignment.bicep' = {
  name: 'backendBlobRole'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: backendApp.outputs.principalId
    // Storage Blob Data Contributor
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }
}

// Function App storage roles are assigned above (before the Function App module)
// using the user-assigned managed identity to avoid the chicken-and-egg problem.

// The system-assigned identity also needs storage roles for internal host
// operations like BlobStorageSecretsRepository and the AzureWebJobsStorage
// health check, which may use the system MI even when __clientId is set.
// Storage Blob Data Owner (system MI)
module funcSysMiBlobOwner './modules/storage-role-assignment.bicep' = {
  name: 'funcSysMiBlobOwner'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionApp.outputs.principalId
    roleDefinitionId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  }
}

// Storage Queue Data Contributor (system MI)
module funcSysMiQueueContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcSysMiQueueContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionApp.outputs.principalId
    roleDefinitionId: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  }
}

// Storage Table Data Contributor (system MI)
module funcSysMiTableContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcSysMiTableContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionApp.outputs.principalId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
  }
}

// Storage Account Contributor (system MI)
module funcSysMiAccountContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcSysMiAccountContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionApp.outputs.principalId
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }
}

// Storage File Data Privileged Contributor (system MI)
module funcSysMiFileContributor './modules/storage-role-assignment.bicep' = {
  name: 'funcSysMiFileContributor'
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: functionApp.outputs.principalId
    roleDefinitionId: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
  }
}

/* ─── RBAC: Cognitive Services User (Document Intelligence) ─── */
// Role ID: a97b65f3-24c7-4388-baec-2e87135dc908

// User-assigned MI — used by AzureWebJobsStorage and Durable Functions host
module functionDocIntelRole './modules/cognitive-services-role-assignment.bicep' = {
  name: 'functionDocIntelRole'
  params: {
    accountName: documentIntelligence.outputs.name
    principalId: functionIdentity.outputs.principalId
    // Cognitive Services User
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
  }
}

// System-assigned MI — DefaultAzureCredential() in application code uses this
// identity when no explicit client ID hint is passed to the credential constructor.
module functionDocIntelRoleSysMi './modules/cognitive-services-role-assignment.bicep' = {
  name: 'functionDocIntelRoleSysMi'
  params: {
    accountName: documentIntelligence.outputs.name
    principalId: functionApp.outputs.principalId
    // Cognitive Services User
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
  }
}

/* ─── RBAC: Cognitive Services OpenAI User (Azure OpenAI) ─── */
// Role ID: 5e0bd9bd-7b93-4f28-af87-19fc36ad61bd

// User-assigned MI
module functionOpenAiRole './modules/cognitive-services-role-assignment.bicep' = {
  name: 'functionOpenAiRole'
  params: {
    accountName: openAi.outputs.name
    principalId: functionIdentity.outputs.principalId
    // Cognitive Services OpenAI User
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
  }
}

// System-assigned MI — DefaultAzureCredential() in application code
module functionOpenAiRoleSysMi './modules/cognitive-services-role-assignment.bicep' = {
  name: 'functionOpenAiRoleSysMi'
  params: {
    accountName: openAi.outputs.name
    principalId: functionApp.outputs.principalId
    // Cognitive Services OpenAI User
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
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

@description('The Application Insights connection string.')
output appInsightsConnectionString string = appInsights.outputs.connectionString
