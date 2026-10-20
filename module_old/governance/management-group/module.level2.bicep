targetScope = 'managementGroup'

param parentId string
param managementGroup {
  name: string
  childs: object[]?
}

resource managementGroupResource 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroup.name
  scope: tenant()

  properties: {
    details: {
      parent: {
        id: parentId
      }
    }
    displayName: managementGroup.name
  }
}
