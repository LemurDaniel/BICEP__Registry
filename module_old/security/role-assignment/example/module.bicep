param location string = resourceGroup().location
// param environment string

var varDefaultSettings = {
  deploymentBaseName: '${substring(uniqueString(az.resourceGroup().name), 0, 8)}-identity'
}

resource resStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: uniqueString('${varDefaultSettings.deploymentBaseName}-st')
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

module modRoleAssignment '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}.auth'
  params: {
    resourceId: resStorage.id
    roleAssignments: [
      {
        principalId: '468e1b90-5ffa-4207-ad02-326a614b6990'
        roleDefinitionName: 'Contributor'
      }
      {
        principalId: '468e1b90-5ffa-4207-ad02-326a614b6990'
        roleDefinitionNames: [
          'Owner'
          'Reader'
        ]
      }
    ]
  }
}
