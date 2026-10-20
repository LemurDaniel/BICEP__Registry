import { defaultSchema } from '../../../governance/naming-schema/module.bicep'

var varDeploymentBaseName = substring(uniqueString(az.resourceGroup().name), 0, 8)

param location string = resourceGroup().location
param environment string

module modKV '../module.bicep' = {
  name: '${varDeploymentBaseName}.kv'
  params: {
    location: location

    namingSchema: defaultSchema
    naming: {
      environment: environment
      name: 'bla1234'
    }

    sku: 'standard'
    network: {
      access: 'SelectedNetworksAndIPs'
      ipRules: [
        '0.0.0.0'
      ]
    }

    roleAssignments: [
      {
        principalId: deployer().objectId
        roleDefinitionNames: [
          'Reader'
          'Contributor'
        ]
      }
    ]
  }
}
