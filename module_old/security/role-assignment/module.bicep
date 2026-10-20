
@maxLength(60)
@description('''
  This can adjust the name of the sub-deployment.
  Be aware, if the resulting name is longer than 64 characters, the deployment will fail.

  64 - 4 characters for '.ras'-suffix in the sub deployment.
''')
param subDeploymentPrefix string = length('${deployment().name}.ras') > 64
  ? uniqueString(deployment().name)
  : deployment().name

////////////////////////////////////////////////
//// Location and Tags

//param location string = resourceGroup().location
//param tags {
//  *: string
//} = {}

////////////////////////////////////////////////
//// Naming Module

// import { name, typeNaming } from '../../governance/naming/module.bicep'
// 
// @description('Provide a custom naming schema for the resource. Default is used if not provided.')
// param schema object
// @description('Define any parameters used for name generation here.')
// param naming typeNaming
// var varNaming = union(naming, {
//   location: location
// })

////////////////////////////////////////////////

@export()
type typeAsExtensionResource = {
  principalId: string

  roleDefinitionName: string?
  roleDefinitionNames: string[]?
}[]

////////////////////////////////////////////////
//// Module Parameter

@description('''
The resource ID used for alle role assignments. 
If not provided, the resource Id on each role assignment must be set.
''')
param resourceId string?

param roleAssignments {
  principalId: string

  @description('Set a resource ID for each role assignment. If not provided, the resource ID will be set to the parent resource ID.')
  resourceId: string?

  roleDefinitionName: string?
  roleDefinitionNames: string[]?

  @description('Can be used for role definition names not available in the built-in roles.')
  roleDefinitionId: string?
  roleDefinitionIds: string[]?
}[]

var paramRoleAssigments = [
  for (item, index) in roleAssignments: {
    principalId: item.principalId
    resourceId: item.?resourceId ?? resourceId ?? fail('''
      No resource ID provided for role assignment.
      - Provide a resource ID as module parameter
      - Or set the resourceId property on each role assignment
    ''')

    failChecks: {
      dont_use_both_properties: length(filter(
          [
            !empty(item.?roleDefinitionName)
            !empty(item.?roleDefinitionNames)
            !empty(item.?roleDefinitionId)
            !empty(item.?roleDefinitionIds)
          ],
          arg => arg == true
        )) > 1
        ? fail('''
      Only use one of the following properties:
      - roleDefinitionName: single role definition
      - roleDefinitionNames: array of role definitions
      - roleDefinitionId: single role definition ID
      - roleDefinitionIds: array of role definition IDs
      ''')
        : ''

      either_property_required: length(filter(
          [
            !empty(item.?roleDefinitionName)
            !empty(item.?roleDefinitionNames)
            !empty(item.?roleDefinitionId)
            !empty(item.?roleDefinitionIds)
          ],
          arg => arg == true
        )) == 0
        ? fail('''
      Either roleDefinition or roleDefinitions must be provided!
      - roleDefinitionName: single role definition
      - roleDefinitionNames: array of role definitions
      ''')
        : ''
    }

    roleDefinitionName: item.?roleDefinitionName
    roleDefinitionNames: item.?roleDefinitionNames

    roleDefinitionId: item.?roleDefinitionId
    roleDefinitionIds: item.?roleDefinitionIds
  }
]

var varRoleAssignmentsFlat = flatten(varRoleAssigments)
var varRoleAssigments = [
  for (item, index) in paramRoleAssigments: concat(
    // Handle single role definition name
    !empty(item.?roleDefinitionName) ? [item] : [],

    // Handle single role definition ID
    !empty(item.?roleDefinitionId) ? [item] : [],

    // Handle multiple role definition names
    map(item.?roleDefinitionNames ?? [], role => {
      principalId: item.principalId
      resourceId: item.resourceId
      roleDefinitionName: role
    }),

    // Handle multiple role definition IDs
    map(item.?roleDefinitionIds ?? [], role => {
      principalId: item.principalId
      resourceId: item.resourceId
      roleDefinitionId: role
    })
  )
]

// A unique list of role definitions. Union removes all duplicates.
var varRoleDefinitionNames = map(
  filter(varRoleAssignmentsFlat, arg => !empty(arg.roleDefinitionName)),
  arg => arg.roleDefinitionName
)
var varUniqueRoleDefinitionNames = union(varRoleDefinitionNames, varRoleDefinitionNames)

////////////////////////////////////////////////
//// Role Definition Lookup

import { builtInRole } from '../../utility/role-utility/var.builtIn.bicep'
resource resRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = [
  for (role, index) in varUniqueRoleDefinitionNames: {
    name: builtInRole[role]
  }
]

// reference the role definitions by their name
// varRoleDefinitionReference['Reader'].id
var varRoleDefinitionReference = toObject(varRoleDefinitionArray, arg => arg.role, arg => arg)
var varRoleDefinitionArray = [
  for (role, index) in varUniqueRoleDefinitionNames: {
    role: role
    id: resRoleDefinition[index].id
  }
]

////////////////////////////////////////////////
//// Role Assignment

module modRoleAssignments 'module.roles.json' = {
  name: '${subDeploymentPrefix}.ras'
  params: {
    assignments: [
      for (item, index) in varRoleAssignmentsFlat: {
        resourceId: item.resourceId
        principalId: item.principalId
        roleDefinitionId: item.?roleDefinitionId ?? varRoleDefinitionReference[item.?roleDefinitionName].id ?? fail('''
          No role Definition ID found for role definition name: ${item.?roleDefinitionName}
          ''')
      }
    ]
  }
}
