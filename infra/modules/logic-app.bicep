metadata name = 'Logic App'
metadata description = 'Deploys an Azure Logic App (Consumption) for email notification workflows.'

import { DeploymentConfig } from '../types.bicep'

/* ─── Parameters ─── */

@description('Common deployment configuration.')
param config DeploymentConfig

/* ─── Resources ─── */

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-${config.prefix}-notify-${config.environment}'
  location: config.location
  tags: config.tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                recipientEmail: { type: 'string' }
                subject: { type: 'string' }
                body: { type: 'string' }
              }
              required: [
                'recipientEmail'
                'subject'
                'body'
              ]
            }
          }
        }
      }
      actions: {
        Response: {
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 202
            body: {
              message: 'Notification request accepted.'
            }
          }
        }
      }
      outputs: {}
    }
  }
}

/* ─── Outputs ─── */

@description('The resource ID of the Logic App.')
output id string = logicApp.id

@description('The name of the Logic App.')
output name string = logicApp.name
