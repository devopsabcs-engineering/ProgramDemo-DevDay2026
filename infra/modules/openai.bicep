metadata name = 'Azure OpenAI'
metadata description = 'Deploys an Azure OpenAI account with a gpt-4o-mini model deployment for AI-powered document summarization.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Override location for the OpenAI resource (some models are not available in all regions).')
param location string = config.location

@description('Chat model deployment name.')
param chatModelDeploymentName string = 'gpt-4o-mini'

/* ─── Variables ─── */

var resourceToken = '${config.prefix}-${config.environment}-${config.instanceNumber}'

/* ─── Resources ─── */

resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'oai-${resourceToken}'
  location: location
  tags: config.tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'oai-${resourceToken}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: openAi
  name: chatModelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
  }
}

/* ─── Outputs ─── */

@description('Azure OpenAI endpoint URI.')
output endpoint string = openAi.properties.endpoint

@description('Deployment name for use in Function App config.')
output deploymentName string = chatDeployment.name

@description('Resource ID for RBAC assignments.')
output id string = openAi.id

@description('The name of the OpenAI resource.')
output name string = openAi.name
