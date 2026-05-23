@maxLength(59)
@description('''
  This can adjust the name of the sub-deployment.
  Be aware, if the resulting name is longer than 64 characters, the deployment will fail.
''')
param subDeploymentPrefix string = length('${deployment().name}.st.auth') > 64
  ? uniqueString(deployment().name)
  : deployment().name

////////////////////////////////////////////////
//// Module Parameter

param resourceId string

param roleAssignment {
  principalId: string
  roleDefinitions: string[]
}[]

var paramRoleAssignments = [
  for entry in roleAssignment: {
    resourceId: resourceId
    principalId: entry.principalId
    roleDefinitions: entry.roleDefinitions
  }
]

////////////////////////////////////////////////
//// Deployment

module modRoleAssignments 'module.roles.json' = {
  name: '${subDeploymentPrefix}.role'
  params: {
    assignments: [
      for entry in uniqueAssignments(paramRoleAssignments): {
        name: entry.name
        resourceId: entry.resourceId
        principalId: entry.principalId
        roleDefinitionId: entry.roleDefinitionId
      }
    ]
  }
}

////////////////////////////////////////////////
//// Helper Functions

@description('Use in conjunction with utilityRoleAssignments-function.')
type typeUtilityRoleAssignments = {
  principalId: string
  resourceId: string
  roleDefinitions: string[]
}[]?

@export()
@description('Converts a role assignment mapping to a list of role assignments for easier processing.')
func uniqueAssignments(roleAssignments typeUtilityRoleAssignments) {
  name: string
  roleDefinitionId: string
  resourceId: string
  principalId: string
}[] =>
  flatten(map(
    roleAssignments ?? [],
    item =>
      map(item.roleDefinitions, role => {
        name: guid(item.resourceId, item.principalId, role)
        roleDefinitionId: roleDefinitions(role).id
        resourceId: item.resourceId
        principalId: item.principalId
      })
  ))
