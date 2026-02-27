metadata name = 'Container Registry Private Endpoint'
metadata description = 'Deploys a private endpoint for Azure Container Registry with private DNS zone linked to the VNet. Requires Premium SKU on the ACR.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Name of the container registry.')
param registryName string

@description('Resource ID of the container registry.')
param registryId string

@description('Resource ID of the subnet for private endpoints.')
param privateEndpointSubnetId string

@description('Resource ID of the VNet to link private DNS zones to.')
param vnetId string

/* ─── Resources ─── */

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: config.tags
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-acr-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${registryName}'
  location: config.location
  tags: config.tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-acr'
        properties: {
          privateLinkServiceId: registryId
          groupIds: ['registry']
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acr-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
