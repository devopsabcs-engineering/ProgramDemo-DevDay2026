metadata name = 'ACR Role Assignment'
metadata description = 'Assigns a role to a principal on a specific Azure Container Registry. Exists as a module because role assignment name and scope must be resolvable at the module boundary, not from parent module outputs directly.'

/* ─── Parameters ─── */

@description('Name of the existing container registry.')
param registryName string

@description('Principal (object) ID to assign the role to.')
param principalId string

@description('Role definition GUID to assign.')
param roleDefinitionId string

@description('Principal type (ServicePrincipal, User, Group).')
param principalType string = 'ServicePrincipal'

/* ─── Resources ─── */

resource registry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: registryName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, principalId, roleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}
