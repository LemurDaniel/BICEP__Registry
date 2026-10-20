targetScope = 'subscription'
////////////////////////////////////////////////
//// Location and Tags

param subDeploymentName string = deployment().name
param location string = 'global'
param tags {
  *: string
} = {}

////////////////////////////////////////////////
//// Naming Module

import { name, nameResourceGroup, typeNaming } from '../../../governance/naming/module.bicep'

@description('Provide a custom naming schema for the resource. Default is used if not provided.')
param schema object
@description('Define any parameters used for name generation here.')
param naming typeNaming
var varNaming = union(naming, {
  location: location
})

////////////////////////////////////////////////
//// Module Parameter

import { configuration } from '../module.types.bicep'
param config configuration

////////////////////////////////////////////////

resource resGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: nameResourceGroup(location, varNaming, schema)
  location: location
  tags: tags
}
module modAppGateway '../resource-group/module.bicep' = {
  name: '${subDeploymentName}-rg'
  scope: resGroup
  params: {
    schema: schema
    naming: varNaming
    location: location
    tags: tags
    config: config
  }
}
