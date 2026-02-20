metadata name = 'Virtual Network'
metadata description = 'Deploys a VNet with two subnets: one for private endpoints, one for App Service regional VNet integration.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Resources ─── */

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${config.prefix}-${config.environment}-${config.instanceNumber}'
  location: config.location
  tags: config.tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        // Subnet used by private endpoints (network policies must be Disabled)
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        // Subnet delegated to App Service for regional VNet integration
        name: 'snet-app'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'delegation-appservice'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the VNet.')
output vnetId string = vnet.id

@description('The resource ID of the private endpoint subnet (snet-pe).')
output privateEndpointSubnetId string = vnet.properties.subnets[0].id

@description('The resource ID of the App Service VNet integration subnet (snet-app).')
output appSubnetId string = vnet.properties.subnets[1].id
