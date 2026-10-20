import { defaultSchema } from '../../../governance/naming-schema/module.bicep'


param location string = resourceGroup().location
param environment string

var varDeploymentBaseName = substring(uniqueString(az.resourceGroup().name), 0, 8)

module modKV '../../key-vault/module.bicep' = {
  name: '${varDeploymentBaseName}.kv'
  params: {
    location: location
    namingSchema: defaultSchema
    naming: {
      environment: environment
      name: uniqueString(varDeploymentBaseName)
    }
    
    network: {
      access: 'PublicInternet'
    }
  }
}

module modIdentity '../module.bicep' = {
  name: '${varDeploymentBaseName}.id'
  params: {
    location: location
    namingSchema: defaultSchema
    naming: {
      environment: environment
      name: uniqueString(varDeploymentBaseName)
    }
  }
}
