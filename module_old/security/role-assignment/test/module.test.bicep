test testMain '../module.bicep' = {
  params: {
    roleAssignment: [
      {
        resourceId: ''
        principalId: deployer().objectId
        roleDefinitions: [
          'Reader'
          'Contributor'
        ]
      }
    ]
  }
}
