metadata name = 'Document Intelligence'
metadata description = 'Deploys an Azure AI Document Intelligence (Cognitive Services FormRecognizer) account for PDF text extraction.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Variables ─── */

var resourceToken = '${config.prefix}-${config.environment}-${config.instanceNumber}'

/* ─── Resources ─── */

resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'docintel-${resourceToken}'
  location: config.location
  tags: config.tags
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'docintel-${resourceToken}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

/* ─── Outputs ─── */

@description('Document Intelligence endpoint URI.')
output endpoint string = documentIntelligence.properties.endpoint

@description('Resource ID for RBAC assignments.')
output id string = documentIntelligence.id

@description('The name of the Document Intelligence resource.')
output name string = documentIntelligence.name
