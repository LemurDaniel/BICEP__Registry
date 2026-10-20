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

// Self-Referencing modules are not allowed. Therefore using one for each mgm level.
module mgmModule './module.level2.bicep' = [
for child in (managementGroup.?childs ?? []): {

  name: 'mgm.level2.${child.name}'
  params: {
    parentId: managementGroupResource.id
    managementGroup: child
  }
}]
