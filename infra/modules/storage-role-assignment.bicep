metadata name = 'Storage Account Role Assignment'
metadata description = 'Assigns a role to a principal on a specific storage account. Exists as a module because role assignment name and scope must be resolvable at the module boundary, not from parent module outputs directly.'

/* ─── Parameters ─── */

@description('Name of the existing storage account.')
param storageAccountName string

@description('Principal (object) ID to assign the role to.')
param principalId string

@description('Role definition GUID to assign.')
param roleDefinitionId string

@description('Principal type (ServicePrincipal, User, Group).')
param principalType string = 'ServicePrincipal'

/* ─── Resources ─── */

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, principalId, roleDefinitionId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}
