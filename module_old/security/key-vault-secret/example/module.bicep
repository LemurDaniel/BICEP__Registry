import { defaultSchema } from '../../../governance/naming-schema/module.bicep'

var varDeploymentBaseName = substring(uniqueString(az.resourceGroup().name), 0, 8)

param location string = resourceGroup().location
param environment string

module modStorage '../../../storage/storage-account/module.bicep' = {
  name: '${varDeploymentBaseName}.storage'
  params: {
    location: location

    namingSchema: defaultSchema
    naming: {
      environment: environment
      name: 'storage'
    }

    sku: 'Standard_LRS'
    kind: 'StorageV2'
  }
}

module modKv '../../key-vault/module.bicep' = {
  name: '${varDeploymentBaseName}.kv'
  params: {
    location: location

    namingSchema: defaultSchema
    naming: {
      environment: environment
      name: 'bla1234'
    }

    sku: 'standard'
  }
}

module modSecrets '../module.bicep' = {
  name: '${varDeploymentBaseName}-secrets'
  params: {
    keyVaultName: modKv.outputs.name
    secrets: {
      primaryAccessKey: {
        value: modStorage.outputs.credentials.primaryAccessKey
      }
      secondaryAccessKey: {
        value: modStorage.outputs.credentials.secondaryAccessKey
      }
    }
  }
}
