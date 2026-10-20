
import { defaultSchema } from '../../../../governance/naming-schema/module.bicep'

param exampleIdentifier string = 'module-registry.solutions.resource-group.application-gateway'
//
//

param location string = resourceGroup().location
param environment string
param config object

module modSolutionAppGateway '../module.bicep' = {
  name: '${substring(uniqueString(exampleIdentifier), 0, 8)}-rg'
  params: {
    location: location
    schema: defaultSchema
    naming: {
      name: uniqueString(exampleIdentifier)
      environment: environment
    }
    config: config
  }
}



