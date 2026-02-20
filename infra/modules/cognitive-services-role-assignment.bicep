metadata name = 'Cognitive Services Role Assignment'
metadata description = 'Assigns a role to a principal on a specific Cognitive Services account. Exists as a module because role assignment name and scope must be resolvable at the module boundary, not from parent module outputs directly.'

/* ─── Parameters ─── */

@description('Name of the existing Cognitive Services account.')
param accountName string

@description('Principal (object) ID to assign the role to.')
param principalId string

@description('Role definition GUID to assign.')
param roleDefinitionId string

@description('Principal type (ServicePrincipal, User, Group).')
param principalType string = 'ServicePrincipal'

/* ─── Resources ─── */

resource cognitiveServicesAccount 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = {
  name: accountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cognitiveServicesAccount.id, principalId, roleDefinitionId)
  scope: cognitiveServicesAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}
