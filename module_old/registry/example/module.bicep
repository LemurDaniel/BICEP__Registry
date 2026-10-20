import { defaultSchema } from '../../../governance/naming-schema/module.bicep'



param location string = resourceGroup().location
param environment string = 'dev'

var varDefaultSettings = {
  deploymentBaseName: '${substring(uniqueString(az.resourceGroup().name), 0, 8)}-registry'
}

module container_registry0 '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}-acr-0'
  params: {
    location: location
    schema: defaultSchema
    naming: {
      environment: environment
      name: '${uniqueString(varDefaultSettings.deploymentBaseName)}0'
    }
    config: {}
  }
}

module container_registry1 '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}-acr-1'
  params: {
    location: location
    schema: defaultSchema
    naming: {
      environment: environment
      name: '${uniqueString(varDefaultSettings.deploymentBaseName)}1'
    }
    config: {}
  }
}
