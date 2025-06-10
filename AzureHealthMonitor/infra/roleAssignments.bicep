targetScope = 'subscription'

@description('Principal ID of the managed identity')
param principalId string

// Reader role at subscription level for resource inventory
resource subscriptionReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, principalId, 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Resource Health Reader role for service health monitoring  
resource healthReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, principalId, '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05') // Monitoring Reader
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output readerRoleAssignmentId string = subscriptionReaderRole.id
output healthReaderRoleAssignmentId string = healthReaderRole.id
