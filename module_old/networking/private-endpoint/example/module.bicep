import { schema } from '../../../governance/naming-schema/module.bicep'

param location string = resourceGroup().location
param environment string = 'dev'

var varDefaultSettings = {
  deploymentBaseName: '${substring(uniqueString(az.resourceGroup().name), 0, 8)}-privateendpoint'
}

resource resStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: uniqueString('${varDefaultSettings.deploymentBaseName}.storage')
  location: 'westeurope'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

module modVnet 'br:bicepnamingpoc001.azurecr.io/networking/virtual-network:4.7.0' = {
  name: '${varDefaultSettings.deploymentBaseName}.vnet'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      overwrite: 'vnet-moduleregistry-${environment}-01'
      environment: environment
      projectName: 'moduleregistry'
      index: 1
    }
    config: {
      addressSpace: '10.0.0.0/24'
      subnet: {
        private_endpoint: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    }
  }
}

module modPrivateEndpoint '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}.pep1'
  params: {
    location: location

    namingSchema: schema.indexBased
    naming: {
      environment: environment
      projectName: 'moduleregistry'
      index: 1
    }

    resourceId: resStorage.id
    network: {
      subnetId: modVnet.outputs.subnet.private_endpoint.id
      staticIP: '10.0.0.4'
    }
  }
}

module modPrivateEndpoint2 '../module.bicep' = {
  name: '${varDefaultSettings.deploymentBaseName}.pep2'
  params: {
    location: location

    namingSchema: schema.indexBased
    naming: {
      environment: environment
      projectName: 'moduleregistry'
      index: 2
    }

    resourceId: resStorage.id
    network: {
      subnetId: modVnet.outputs.subnet.private_endpoint.id
      staticIP: '10.0.0.7'
    }
  }
}
