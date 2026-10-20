// 64 - 8 characters for '.id.auth'-Suffix in the sub deployment.
@maxLength(56)
@description('''
  This can adjust the name of the sub-deployment.
  Be aware, if the resulting name is longer than 64 characters, the deployment will fail.

  64 - 8 characters for '.id.auth'-Suffix in the sub deployment.
''')
param subDeploymentPrefix string = length('${deployment().name}.kv.auth') > 64
  ? uniqueString(deployment().name)
  : deployment().name

////////////////////////////////////////////////
//// Location and Tags

param location string = resourceGroup().location
param tags {
  *: string
} = {}

////////////////////////////////////////////////
//// Naming Module

import { genNameId, typeNaming } from '../../governance/naming/module.bicep'

@description('Provide a naming schema for name generation.')
param namingSchema object?
@description('Provide a naming id to uniquely identify in the naming schema.')
param namingId string = 'default'
@description('Define any parameters used for name generation here.')
param naming typeNaming?

var useNamingModule = !empty(namingSchema)

@description('''
The name of the Resource.
- If a naming schema is provided, this will be added to the parameters of the naming module.
- Otherwise it will be use as the full name of the resource.
''')
param name string?

var varName = useNamingModule
  ? genNameId('Microsoft.ManagedIdentity/userAssignedIdentities', namingId, namingSchema ?? {}, location, {
      name: name ?? naming.?name
      ...naming ?? {}
    })
  : name ?? fail('If "namingSchema" is not provided, "name" must be provided.')

////////////////////////////////////////////////
//// Module Parameter

resource resIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: varName
  location: location
  tags: tags
}

output apiVersion string = resIdentity.apiVersion
output id string = resIdentity.id
output name string = resIdentity.name
output principalId string = resIdentity.properties.principalId

/*

  ###############################################################
  #### EXTENSION RESOURCE: Role Assignments

*/

import { typeAsExtensionResource } from '../../security/role-assignment/module.bicep'
param roleAssignments typeAsExtensionResource = []
module modRoleAssignments '../../security/role-assignment/module.bicep' = if (length(roleAssignments) > 0) {
  name: '${subDeploymentPrefix}.id.auth'
  params: {
    resourceId: resIdentity.id
    roleAssignments: roleAssignments
  }
}
