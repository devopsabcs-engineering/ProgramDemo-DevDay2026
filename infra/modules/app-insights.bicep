metadata name = 'Application Insights'
metadata description = 'Deploys a Log Analytics Workspace and Application Insights resource for end-to-end observability across backend, frontend, and Azure Functions.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Resources ─── */

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: 30
  }
}

/* ─── Outputs ─── */

@description('The Application Insights connection string for SDK/agent configuration.')
output connectionString string = appInsights.properties.ConnectionString

@description('The Application Insights instrumentation key (legacy).')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The resource ID of the Application Insights instance.')
output id string = appInsights.id

@description('The name of the Log Analytics Workspace.')
output logAnalyticsName string = logAnalytics.name
