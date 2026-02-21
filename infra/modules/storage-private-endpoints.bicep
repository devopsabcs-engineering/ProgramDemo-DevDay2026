metadata name = 'Storage Account Private Endpoints'
metadata description = 'Deploys private endpoints for blob, queue, table, and file services on a storage account, with corresponding private DNS zones linked to the VNet.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

@description('Name of the existing storage account.')
param storageAccountName string

@description('Resource ID of the subnet for private endpoints.')
param privateEndpointSubnetId string

@description('Resource ID of the VNet to link private DNS zones to.')
param vnetId string

/* ─── Variables ─── */

// Each storage sub-resource (blob, queue, table, file) needs its own
// private endpoint, DNS zone, and DNS zone group.
var storageServices = [
  {
    name: 'blob'
    groupId: 'blob'
    dnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
  }
  {
    name: 'queue'
    groupId: 'queue'
    dnsZoneName: 'privatelink.queue.${environment().suffixes.storage}'
  }
  {
    name: 'table'
    groupId: 'table'
    dnsZoneName: 'privatelink.table.${environment().suffixes.storage}'
  }
  {
    name: 'file'
    groupId: 'file'
    dnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
  }
]

/* ─── Resources ─── */

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Private DNS Zones for each storage service
resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [
  for svc in storageServices: {
    name: svc.dnsZoneName
    location: 'global'
    tags: config.tags
  }
]

// Link each DNS zone to the VNet
resource dnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [
  for (svc, i) in storageServices: {
    parent: privateDnsZones[i]
    name: 'link-${svc.name}-${config.prefix}-${config.environment}-${config.instanceNumber}'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: vnetId
      }
      registrationEnabled: false
    }
  }
]

// Private endpoints
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [
  for (svc, i) in storageServices: {
    name: 'pe-${storageAccountName}-${svc.name}'
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
            privateLinkServiceId: storageAccount.id
            groupIds: [svc.groupId]
          }
        }
      ]
    }
  }
]

// DNS zone groups — auto-register the private endpoint IP in the DNS zone
resource dnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [
  for (svc, i) in storageServices: {
    parent: privateEndpoints[i]
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: '${svc.name}-config'
          properties: {
            privateDnsZoneId: privateDnsZones[i].id
          }
        }
      ]
    }
  }
]
