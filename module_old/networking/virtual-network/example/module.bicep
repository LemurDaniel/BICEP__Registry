
import { schema } from '../../../governance/naming-schema/module.bicep'

param location string = resourceGroup().location
param environment string
param config object

var varDefaultSettings = {
  deploymentBaseName: '${substring(uniqueString(az.resourceGroup().name), 0, 8)}-vnet'
}

module modVnetHub '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}-hub'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      environment: environment
      projectName: 'modregistry'
      index: 1
    }
    config: config
  }
}

module modVnetSpoke1 '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}-spoke1'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      environment: environment
      projectName: 'modregistry'
      index: 2
    }
    config: {
      addressSpace: '10.0.32.0/19'
      subnet: {}

      singlePeerings: [
        {
          remoteVnetId: modVnetHub.outputs.id
        }
      ]
    }
  }
}

module modVnetSpoke2 '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}-spoke2'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      environment: environment
      projectName: 'modregistry'
      index: 3
    }
    config: {
      addressSpace: '10.0.64.0/19'
      subnet: {}

      dualPeerings: [
        {
          remoteVnetId: modVnetHub.outputs.id
        }
      ]
    }
  }
}
