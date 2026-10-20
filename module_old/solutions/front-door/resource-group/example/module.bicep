
import { schema } from '../../../../governance/naming-schema/module.bicep'

param exampleIdentifier string = 'module-registry.solutions.resource-group.front-door'
//
//

param location string = resourceGroup().location
param environment string
param config object

module modSolutionFrontDoor '../module.bicep' = {
  name: '${substring(uniqueString(exampleIdentifier), 0, 8)}-rg'
  params: {
    location: location
    schema: schema.indexBased
    naming: {
      environment: environment
      projectName: uniqueString(exampleIdentifier)
    }
    config: config
  }
}
