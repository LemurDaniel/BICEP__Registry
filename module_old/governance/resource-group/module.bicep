targetScope = 'subscription'

import { name, defaultSchema } from '../../governance/naming/module.bicep'

@description('Provide a custom naming schema for the resource. Default is used if not provided.')
param schema object?
@description('Define any parameters used for name generation here.')
param naming {
  index: int?
  overwrite: string?
  *: string?
}

param location string = deployment().location
param tags {
  *: string
} = {}

//param config {} = {}

// var varDefaultSettings = {
//   subdeploymentIdentifier: deployment().name
// }

var varAppliedSettings = {
  naming: {
    schema: schema ?? defaultSchema
    parameters: union(naming, {
      location: location
    })
  }
}

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: name(
    'Microsoft.Resources/resourceGroups',
    varAppliedSettings.naming.schema,
    varAppliedSettings.naming.parameters
  )
  location: location
  tags: tags
}

output apiVersion string = resResourceGroup.apiVersion
output id string = resResourceGroup.id
output name string = resResourceGroup.name
output location string = resResourceGroup.location

output tags object = resResourceGroup.tags

output schema object = varAppliedSettings.naming.schema
output naming object = varAppliedSettings.naming.parameters

output reference object = resourceGroup(resResourceGroup.name)
