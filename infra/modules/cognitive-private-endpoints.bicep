metadata name = 'Cognitive Services Private Endpoints'
metadata description = 'Deploys private endpoints for Azure Cognitive Services accounts (Document Intelligence, OpenAI) with corresponding private DNS zones linked to the VNet. Required when Azure Policy denies public network access.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Name of the Document Intelligence account.')
param docIntelligenceName string

@description('Resource ID of the Document Intelligence account.')
param docIntelligenceId string

@description('Name of the Azure OpenAI account.')
param openAiName string

@description('Resource ID of the Azure OpenAI account.')
param openAiId string

@description('Resource ID of the subnet for private endpoints.')
param privateEndpointSubnetId string

@description('Resource ID of the VNet to link private DNS zones to.')
param vnetId string

/* ─── Variables ─── */

var cognitiveServices = [
  {
    name: docIntelligenceName
    resourceId: docIntelligenceId
    groupId: 'account'
  }
  {
    name: openAiName
    resourceId: openAiId
    groupId: 'account'
  }
]

/* ─── Resources ─── */

// Shared private DNS zone for all Cognitive Services accounts
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.cognitiveservices.azure.com'
  location: 'global'
  tags: config.tags
}

// Also create the OpenAI-specific DNS zone for openai.azure.com endpoints
resource openAiDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: config.tags
}

// Link DNS zones to the VNet
resource cogDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-cog-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

resource openAiDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: openAiDnsZone
  name: 'link-oai-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// Private endpoints for each Cognitive Services account
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [
  for (svc, i) in cognitiveServices: {
    name: 'pe-${svc.name}'
    location: config.location
    tags: config.tags
    properties: {
      subnet: {
        id: privateEndpointSubnetId
      }
      privateLinkServiceConnections: [
        {
          name: 'plsc-${svc.name}'
          properties: {
            privateLinkServiceId: svc.resourceId
            groupIds: [svc.groupId]
          }
        }
      ]
    }
  }
]

// DNS zone groups — register the private endpoint IPs in both DNS zones
resource dnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [
  for (svc, i) in cognitiveServices: {
    parent: privateEndpoints[i]
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'cognitiveservices-config'
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
        {
          name: 'openai-config'
          properties: {
            privateDnsZoneId: openAiDnsZone.id
          }
        }
      ]
    }
  }
]
