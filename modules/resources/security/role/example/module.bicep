module modRoleAssignments '../module.bicep' = {
  name: 'roleAssignment'
  params: {
    resourceId: resourceGroup().id
    roleAssignment: [
      {
        principalId: deployer().objectId
        roleDefinitions: [
          'Reader'
          'Contributor'
        ]
      }
    ]
  }
}
